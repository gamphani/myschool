class CourseController < ApplicationController
  def index
    render :layout => false
  end

  def add_course
    render :layout => false
  end

  def edit_course
    @courses = Course.all
    render :layout => false
  end

  def remove_course
    @courses = Course.all
    render :layout => false
  end

  def view_courses
    @courses = Course.all
    render :layout => false
  end

  def create
    if (Course.create({
        :name => params[:course_name]
      }))
      flash[:notice] = "Operation successful"
      redirect_to :controller => "course", :action => "add_course"
    else
      flash[:error] = "Unable to save. Check for errors and try again"
      render :controller => "course", :action => "add_course"
    end
  end
end
