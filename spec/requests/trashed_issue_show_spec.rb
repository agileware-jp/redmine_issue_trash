# frozen_string_literal: true

require File.expand_path('../rails_helper', __dir__)

RSpec.describe 'Trashed issue show', type: :request do
  INLINE_IMAGE_SYNTAX = {
    'textile' => '!testfile.jpg!',
    'markdown' => '![](testfile.jpg)',
    'common_mark' => '![](testfile.jpg)'
  }.freeze

  let(:user) { create(:user, admin: true) }
  let(:tracker) { create(:tracker) }
  let(:long_text_cf) do
    create(:issue_custom_field, field_format: 'text', trackers: [tracker], is_for_all: true,
                                text_formatting: 'full')
  end

  before do
    allow_any_instance_of(User).to receive(:deliver_security_notification) { nil }
    allow(User).to receive(:current) { user }
  end

  # 添付を持つチケットを作って削除する。
  # 本体は描画対象オブジェクトの #attachments からインライン添付や
  # {{thumbnail}} マクロを解決するが、TrashedIssue#rebuild が返す Issue は
  # 復元用の未保存コピー(id が nil)を持つ。これが本体へ渡ると Redmine 7.0 は
  # InlineAttachmentsScrubber の sort_by { [created_on, id] } で ArgumentError になり、
  # 6.1 以前でも AttachmentPatch に除外されて添付を解決できない。
  def trash_issue(description: 'description', notes: nil, cf_value: nil)
    values = cf_value ? { long_text_cf.id => cf_value } : {}
    issue = create(:issue, tracker: tracker, description: description, custom_field_values: values)
    create(:attachment, container: issue).update!(filename: 'testfile.jpg')
    if notes
      issue.reload.init_journal(user, notes)
      issue.save!
    end
    issue.reload.destroy
    TrashedIssue.last
  end

  def image_sources(selector)
    Nokogiri::HTML(response.body).css("#{selector} img").map { |img| img['src'] }
  end

  subject { get "/trashed_issues/#{trashed.id}" }

  let(:attachment) { trashed.attachments.find { |a| a.filename == 'testfile.jpg' } }
  let(:download_path) { "/attachments/download/#{attachment.id}/testfile.jpg" }

  # 利用できる記法は Redmine のバージョンと同梱 gem で変わるため、
  # その環境が実際に提供する記法すべてで確認する。
  Redmine::WikiFormatting.format_names.to_a.each do |format|
    context "with #{format}" do
      before { Setting.text_formatting = format }

      let(:inline_image) { INLINE_IMAGE_SYNTAX.fetch(format) }

      context 'when the description has an inline image' do
        let!(:trashed) { trash_issue(description: "#{inline_image}\r\n") }

        it 'renders without an internal error' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'resolves the inline image to the attachment kept in the trash' do
          subject
          expect(image_sources('div.description')).to eq [download_path]
        end
      end

      context 'when a journal note has an inline image' do
        let!(:trashed) { trash_issue(notes: "#{inline_image}\r\n") }

        it 'resolves the inline image to the attachment kept in the trash' do
          subject
          expect(image_sources('#history')).to eq [download_path]
        end
      end

      context 'when a long text custom field has an inline image' do
        let!(:trashed) { trash_issue(cf_value: "#{inline_image}\r\n") }

        it 'resolves the inline image to the attachment kept in the trash' do
          subject
          expect(image_sources('div.attribute')).to eq [download_path]
        end
      end

      context 'when the description uses the thumbnail macro' do
        let!(:trashed) { trash_issue(description: "{{thumbnail(testfile.jpg)}}\r\n") }

        it 'resolves the macro to the attachment kept in the trash' do
          subject
          expect(response.body).not_to include 'Error executing the <strong>thumbnail</strong> macro'
          expect(image_sources('div.description').first).to include "/attachments/thumbnail/#{attachment.id}"
        end
      end
    end
  end
end
