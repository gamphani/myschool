class ParentController < ApplicationController
  def index
    @class_rooms = ClassRoom.find(:all).map(&:name)
    class_rooms = ClassRoom.find(:all)
    hash = {}
    @total_guardians = []
    @students_with_guardians = []
    @students_without_guardians = []
    
    (class_rooms || []).each do |class_room|
      class_room_id = class_room.id
      hash[class_room_id] = {}
      total_guardians = 0
      
      class_room.class_room_students.each do |crs|
        next if crs.student.blank?
        next if crs.student.student_parent.blank?
        total_guardians += 1 #Counting available guardians per class
      end

      hash[class_room_id]["total_guardians"] = total_guardians
      with_guardians = 0
      without_guardians = 0

      class_room.class_room_students.each do |crs|
        next if crs.student.blank?
        if crs.student.student_parent.blank?
          without_guardians += 1
        end
        unless crs.student.student_parent.blank?
          with_guardians += 1
        end
      end
      
      hash[class_room_id]["with_guardians"] = with_guardians
      hash[class_room_id]["without_guardians"] = without_guardians
    end

    @statistics = hash.sort_by{|key, value|key.to_i}
    
    @statistics.each do |key, value|
      @total_guardians << value["total_guardians"]
      @students_with_guardians << value["with_guardians"]
      @students_without_guardians << value["without_guardians"]
    end
    
    render :layout => false
  end

  def new_parent_guardian
    render :layout => false
  end
  
  def edit_parent_guardian
    @parents = Parent.all
    render :layout => false
  end
  
  def edit_me
    parent_id = params[:parent_id]
    @parent = Parent.find(parent_id)
    if request.method == :post
      if (@parent.update_attributes({
          :fname => params[:first_name],
          :lname => params[:last_name],
          :gender => params[:gender],
          :email => params[:email],
          :phone => params[:phone],
          :dob => params[:dob].to_date
        }))
        flash[:notice] = "You have successfully edited the details"
        redirect_to :controller => "parent", :action => "edit_parent_guardian" and return
      else
        flash[:error] = "Process aborted. Check for errors and try again"
        redirect_to :controller => "parent", :action => "edit_parent_guardian" and return
      end
    end
    render :layout => false
  end

  def void_parent_guardian
    @parents = Parent.all
    render :layout => false
  end

  def delete_parents
    if (params[:mode] == 'single_entry')
      parent = Parent.find(params[:parent_id])
      parent.delete
      render :text => "true" and return
    end

    parent_ids = params[:parent_ids].split(",")
    (parent_ids || []).each do |parent_id|
        parent = Parent.find(parent_id)
        parent.delete
    end
    render :text => "true" and return
  end

  def filter_guardians
    @class_rooms = [["All", "All"]]
    @class_rooms += ClassRoom.all.collect{|c|[c.name, c.id]}
    
    @parents = Parent.find(:all)
    render :layout => false
  end
  
  def create
    first_name = params[:first_name]
    last_name = params[:last_name]
    gender = params[:gender]
    email = params[:email]
    phone = params[:phone]
    date_of_birth = params[:dob].to_date

    if (Parent.create({
        :fname => first_name,
        :lname => last_name,
        :gender => gender,
        :email => email,
        :phone => phone,
        :dob => date_of_birth
      }))

      if (params[:mode] == 'guardian_edit')
        ActiveRecord::Base.transaction do
          student_parent = StudentParent.find(:last, :conditions => ["student_id =?",
              params[:student_id]])
          student_parent.delete

          StudentParent.create({
            :student_id => params[:student_id],
            :parent_id => Parent.last.id
          })
        end
        flash[:notice] = "Operation successful"
        redirect_to :controller => "student", :action => "select_guardian", :student_id => params[:student_id], :mode => params[:mode] and return
      end

      if (params[:mode].blank?)
        unless params[:student_id].blank?
          if (StudentParent.create({
                :student_id => params[:student_id],
                :parent_id => Parent.last.id
              }))
            flash[:notice] = "Operation successful"
            redirect_to :controller => "student" ,:action => "assign_parent_guardian"
          else
            flash[:error] = "Unable to save. Check for errors and try again"
            redirect_to :controller => "parent", :action => "new_parent_guardian", :first_name => params[:first_name],
              :last_name => params[:last_name], :gender => params[:gender] and return
          end
        end
      end

      flash[:notice] = "Operation successful"
      redirect_to :controller => "parent", :action => "new_parent_guardian" and return #creating a parent without a student ID
    else
      flash[:error] = "Unable to save. Check for errors and try again"
      render :controller => "parent", :action => "new_parent_guardian"
    end
  end

  def search_parents
    first_name = params[:first_name]
    last_name = params[:last_name]
    gender = params[:gender]
    conditions = ""
    multiple = false
    unless first_name.blank?
      multiple = true
      conditions += "fname LIKE '%#{first_name}%'"
    end

    unless last_name.blank?
      multiple = true
      conditions += ' AND ' unless conditions.blank?
      conditions += "lname LIKE '%#{last_name}%' "
    end

    unless gender.blank?
      conditions += ' AND ' if multiple
      conditions += "gender = '#{gender}' "
    end

    unless conditions.blank?
      parents = Parent.find_by_sql("SELECT * FROM parent WHERE #{conditions}")
    else
      parents = Parent.all
    end

    hash = {}
    parents.each do |parent|
      parent_id = parent.id.to_s
      hash[parent_id] = {}
      hash[parent_id]["fname"] = parent.fname.to_s
      hash[parent_id]["lname"] = parent.lname.to_s
      hash[parent_id]["phone"] = parent.phone
      hash[parent_id]["email"] = parent.email
      hash[parent_id]["gender"] = parent.gender
      hash[parent_id]["dob"] = parent.dob.to_date.strftime("%d-%b-%Y")
      hash[parent_id]["join_date"] = parent.created_at.to_date.strftime("%d-%b-%Y")
    end
    render :json => hash and return
  end
  
end
