class UserFile < ActiveRecord::Base
  has_attached_file :attachment, :path => ':rails_root/public/uploads/:rails_env/:id/:style/:id', :restricted_characters => RESTRICTED_CHARACTERS
  do_not_validate_attachment_file_type :attachment

  belongs_to :folder
  has_many :share_links, :dependent => :destroy

  validates_attachment_presence :attachment, :message => I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  validates_presence_of :folder_id
  validates_uniqueness_of :attachment_file_name, :scope => 'folder_id', :message => I18n.t(:exists_already, :scope => [:activerecord, :errors, :messages])
  validates_format_of :attachment_file_name, :with => /\A[^\/\\\?\*:|"<>]+\z/, :message => I18n.t(:invalid_characters, :scope => [:activerecord, :errors, :messages])

  def copy(target_folder)
    new_file = self.dup
    new_file.folder = target_folder
    new_file.save!

    path = "#{Rails.root}/uploads/#{Rails.env}/#{new_file.id}/original"
    FileUtils.mkdir_p path
    FileUtils.cp_r self.attachment.path, "#{path}/#{new_file.id}"

    new_file
  end

  def move(target_folder)
    self.folder = target_folder
    save!
  end

  def extension
    File.extname(attachment_file_name)[1..-1]
  end

  def is_image?
    %w(jpg jpeg png bmp gif svg).include?(extension.downcase)
  end

  def is_pdf?
    %w(pdf).include?(extension.downcase)
  end

  def is_markdown?
    %w(md markdown mdown mkdn).include?(extension.downcase)
  end

  def is_asciidoc?
    %w(adoc asc asciidoc).include?(extension.downcase)
  end

  def is_rdoc?
    %w(rdoc).include?(extension.downcase)
  end

  def is_document?
    is_pdf? || is_markdown? || is_asciidoc?
  end

  def is_url?
    %w(url).include?(extension.downcase)
  end

  def is_text?
    %w(txt).include?(extension.downcase)
  end
end
