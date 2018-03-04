class BlogsController < ApplicationController
  unloadable

  helper :attachments
  include AttachmentsHelper
  include ApplicationHelper

  layout 'header', :only => [:index, :new, :show]

  before_filter :find_blog, :except => [:new, :create, :index, :preview, :get_tag_list]
  before_filter :find_user, :only => [:index]
  before_filter :find_optional_project, :except => [:index, :preview, :get_tag_list]
  before_filter :find_project, :only => [:index]
  before_filter :build_new_blog, :only => [:new, :create, :index]
  before_filter :authorize, :except => [:preview, :get_tag_list]
  accept_rss_auth :index

  def index
    @blogs_pages, @blogs = paginate Blog.includes(:author, :project).
                                         where(
                                           @user ? ["author_id = ? and project_id = ?", @user, @project]
                                           : ["project_id = ?", @project]).
                                         order("#{Blog.table_name}.created_on DESC"),
                                    :per_page => 5
    respond_to do |format|
      format.html { render :layout => !request.xhr? }
      format.atom { render_feed(@blogs, :title => "#{Setting.app_title}: Report") }
      format.rss  { render_feed(@blogs, :title => "#{Setting.app_title}: Report", :format => 'rss' ) }
    end
  end

  def show
    html_description @blog.short_description
    if (image = @blog.head_image()) && image.present?
      html_image download_named_attachment_url(image, image.filename)
    end

    @next = Blog.where("id < ?", params[:id]).order("id DESC").first
    @prev = Blog.where("id > ?", params[:id]).order("id ASC").first
  end

  def new
    respond_to do |format|
      format.html { render :action => 'new', :layout => !request.xhr? }
    end
  end

  def create
    if @blog.save
      Attachment.attach_files(@blog, params[:attachments])
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index', :project_id => @project
    else
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
    return render_403 if User.current != @blog.author
    if @blog.update_attributes(params[:blog])
      Attachment.attach_files(@blog, params[:attachments])
      flash[:notice] = l(:notice_successful_update)
    end
    redirect_to :action => 'show', :id => @blog
  end

  def add_comment
    @comment = Comment.new(params[:comment])
    @comment.author = User.current
    if @blog.comments << @comment
      redirect_to :action => 'show', :id => @blog
    else
      render :action => 'show'
    end
  end

  def destroy_comment
    @blog.comments.find(params[:comment_id]).destroy
    redirect_to :action => 'show', :id => @blog
  end

  def destroy
    return render_403 if User.current != @blog.author
    if @blog.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to :action => 'index', :project_id => @project
  end

  def preview
    @text = (params[:blog] ? params[:blog][:description] : nil)
    @blog = Blog.find(params[:id]) if params[:id]
    @attachements = @blog.attachments if @blog
    render :partial => 'common/preview'
  end

  def get_tag_list
    render :json => Blog.tags_on(:tags).map(&:to_s)
  end

private

  def find_blog
    @blog = Blog.find(params[:id])
    @project = @blog.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_user
    @user = User.find(params[:author]) if params[:author]
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    allowed = User.current.allowed_to?({:controller => params[:controller], :action => params[:action]}, @project, :global => true)
    allowed ? true : deny_access
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def build_new_blog
    @blog = Blog.new(params[:blog])
    @blog.author = User.current
    @blog.project = @project
  end

end
