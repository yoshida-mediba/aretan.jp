require 'tempfile'
require 'zip'

module Usability
  module AttachmentsControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :upload, :usability
      end
    end

    module InstanceMethods

      def upload_with_usability
        params[:filename] = params[:filename].gsub(' ', '_') if params[:filename].present?
        upload_without_usability
      end

      def download_all
        begin
          if params[:container_type]
            container = params[:container_type].constantize.where(id: params[:id]).last
          else
            container = Attachment.find(params[:id]).container
          end
          attachments = container.try(:attachments)
          if attachments.blank?
            render_404
            return
          end
          attachments.each do |a|
            unless a.visible?
              deny_access
              return
            end
          end

          download_entries(container, attachments)
        rescue ActiveRecord::RecordNotFound
          render_404
        end
      end

      private

      def download_entries(container, files)
        zip = Tempfile.new(['attachments_zip','.zip'])
        zip_file = Zip::OutputStream.new(zip.path)

        begin
          files.each do |f|
            next unless (f.visible?)

            zip_file.put_next_entry(f.filename)
            if File.exist?(f.diskfile)
              File.open(f.diskfile, 'rb') do |f|
                buffer = ''
                while (buffer = f.read(8192))
                  zip_file.write(buffer)
                end
              end
            end
          end
          zip_file.close
          name = nil
          # name = container.name if (container.respond_to?(:name) && !name)
          # name = container.subject if (container.respond_to?(:subject) && !name)
          name = container.id #if (container.respond_to?(:id) && !name)

          name = (name || '<none>').to_s.truncate(50, omission: '...')

          send_file(zip.path, filename: filename_for_content_disposition(name.to_s + '-' + DateTime.now.strftime('%Y-%m-%d %H%M%S') + '.zip'), type: 'application/zip', disposition: 'attachment')
        ensure
          zip_file.close
          zip.close
        end
      end

    end
  end
end

