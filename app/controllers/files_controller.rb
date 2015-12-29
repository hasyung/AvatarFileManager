class FilesController < ApplicationController
  require 'github/markup'

  before_action :require_existing_file, :only => [:show, :edit, :update, :destroy, :preview]
  before_action :require_existing_target_folder, :only => [:new, :create]

  before_action :require_create_permission, :only => [:new, :create]
  before_action :require_read_permission, :only => :show
  before_action :require_update_permission, :only => [:edit, :update]
  before_action :require_delete_permission, :only => :destroy

  # @file and @folder are set in require_existing_file
  def show
    send_file @file.attachment.path, :filename => @file.attachment_file_name
  end

  def preview
    # Pathname.new(Rails.root.to_s + "/public/common/").children.each { |p| p.unlink }

    @filename = Digest::MD5.hexdigest(Time.new.to_s) + "_" + @file.attachment_file_name

    if @file.is_markdown? || @file.is_asciidoc? || @file.is_rdoc?
      @filename = @filename + ".html"

      File.open(Rails.root.to_s + "/public/common/" + @filename, "w") do |file|
        puts @file.attachment.path + "." + File.extname(@file.attachment_file_name)[1..-1]
        str = GitHub::Markup.render(@file.attachment.path + "." + File.extname(@file.attachment_file_name)[1..-1], File.read(@file.attachment.path))
        file.write(str)
      end
    elsif @file.is_url?
      data = IniParse.parse(File.read(@file.attachment.path))
      hash = data.to_h
      redirect_to hash["InternetShortcut"]["URL"] and return
    else
      FileUtils.cp(@file.attachment.path, Rails.root.to_s + "/public/common/" + @filename)
    end

    redirect_to "/common/#{@filename}"
  end

  # @target_folder is set in require_existing_target_folder
  def new
    @file = @target_folder.user_files.build
  end

  # @target_folder is set in require_existing_target_folder
  def create
    @file = @target_folder.user_files.create(permitted_params.user_file)
    render :nothing => true
  end

  # @file and @folder are set in require_existing_file
  def edit
  end

  # @file and @folder are set in require_existing_file
  def update
    if @file.update_attributes(permitted_params.user_file)
      redirect_to edit_file_url(@file), :notice => t(:your_changes_were_saved)
    else
      render :action => 'edit'
    end
  end

  # @file and @folder are set in require_existing_file
  def destroy
    @file.destroy
    redirect_to @folder
  end

  def exists
    @file = UserFile.new(:attachment_file_name => params[:name].gsub(RESTRICTED_CHARACTERS, '_'))
    @file.folder_id = params[:folder]
    render :json => !@file.valid?
  end

  private

  def require_existing_file
    @file = UserFile.find(params[:id] || params[:file_id])
    @folder = @file.folder
  rescue ActiveRecord::RecordNotFound
    redirect_to Folder.root, :alert => t(:already_deleted, :type => t(:this_file))
  end
end
