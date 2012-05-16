
# ------------ W A K E ----------------
# for Rails 3.2

# todo --- case in/sensitive search

# ked sa rozsirujem este o non-ajax like ajax verziu ... ? treba to ?
# + wrapper treba dodat

# GET   /photos   index   display a list of all photos
# GET   /photos/new   new   return an HTML form for creating a new photo
# POST  /photos   create  create a new photo
# GET   /photos/:id   show  display a specific photo
# GET   /photos/:id/edit  edit  return an HTML form for editing a photo
# PUT   /photos/:id   update  update a specific photo
# DELETE  /photos/:id   destroy   delete a specific photo

# :wake_filter => { 
#   :assoc_item_id => id 
#   :order => order
#   :search => pattern
# }

require "wake/engine"
require 'kaminari'

module Wake
    
  #autoload :WakeHelper, '../app/helpers/wake_helper'
    
  # --- defaults ---
  
  module Defaults
    PER_PAGE = 30
  end
  
  module Extension
    # Wake the controller!
    #
    # options:
    #   * model => :the_model
    #   * prefix => "the_prefix"
    #   * within_module => 'MyEngine'
    #
    def wake(options={})
      # include actions
      self.send :include, ClassMethods
      # i want a helper too
      self.send :helper, :wake
      # setup before filter
      send :before_filter, :wake_prepare
      
      hi_there_hackers = to_s.gsub(/.*::|Controller/,'').singularize
      model_str = (options[:model] ? options[:model].to_s : hi_there_hackers).camelize
      ident_str = (options[:prefix] ? options[:prefix].to_s : hi_there_hackers).underscore

#      _module.const_get '#{model_str}'
      
      send :class_eval, <<-eos
        def _module
          #{options[:within_module] ? options[:within_module].camelize : 'self'}
        end
        def _model
          #{model_str.camelize}
        end
        def _model_sym
          :#{model_str.underscore}
        end
        def _ident
          "#{ident_str}"
        end
      eos
      
    end
  end
  
  
  module ClassMethods
  
    def index
      wake_list
    
      flash.now[:notice] = "wake.#{_ident}.list"
      render :action => _ident+'_list'
    end
    
    def new
      @item ||= _model.new
      params[_model_sym].each{ |k,v| @item.send "#{k}=", v} if params[_model_sym]
   
      flash.now[:notice] = @flash_notice = "wake.#{_ident}.new"
      respond_to do |format|      
        format.html { render :action => _ident+'_form' } #render_list_or_form 
        format.js { render :template => '/wake/form' }
      end
    end
  
  
    def create
      @item ||= _model.new
      params[_model_sym].each{ |k,v| @item.send "#{k}=", v}
          
      if @item.save
        flash[:hilite] = "wake.#{_ident}.create_ok"
        respond_to do |format|
          format.html { redirect_to :action=>'edit', :id=>@item.id }
  #        format.js { render :template=>'wake/create' }
          format.js { render :template=>'/wake/redirect' } 
          # { redirect_to :action=>'index' }
        end
      else # fail
        flash.now[:error] = "wake.#{_ident}.create_error"
        @item.errors.each{ |x| logger.debug x.inspect }
        respond_to do |format|
          format.html { render :action => _ident+'_form' }
          format.js { render :template => '/wake/form' }
        end
      end
    end
  
  
    def show
      edit #flash.now[:notice] = "wake.#{_ident}.show"
  #    raise 'UNSUPPORTED'
    end
  
  
    def edit
      flash.now[:notice] = "wake.#{_ident}.edit"
      respond_to do |format|
  #      format.html { render_list_or_form } #render :action => _ident+'_form'
        format.html { render :action => _ident+'_form' } #
        format.js { render :template=>'/wake/form' }
      end
    end
  
    # list + edit
    # def edit_list
    #   wake_list 
    #   
    #   flash.now[:notice] ||= "wake.#{_ident}.edit"
    #   render :action => _ident+'_list'
    # end
  
  
    def update
#      raise 'hovno'
      @item.attributes= params[_model_sym]
#      params[_ident].each{ |k,v| @item.send "#{k}=", v}
    
      if @item.save
        respond_to do |format|
          format.html do
            flash[:hilite] = "wake.#{_ident}.update_ok"
            redirect_to :action=>'edit'
          end
          format.js do
            flash.now[:hilite] = "wake.#{_ident}.update_ok"
            render :template => '/wake/update'
          end
        end
      else
        logger.debug @item.errors.to_s
        respond_to do |format|
          format.html do 
            flash[:error] = "wake.#{_ident}.update_error"
            render :action => _ident+'_form'
          end
          format.js do
            flash.now[:error] = "wake.#{_ident}.update_error"
           render :template => '/wake/update'
          end
        end
      end
    end
  
  
    def destroy
      if request.xhr?
      else
        ret = @item.destroy 
  #      raise ret.inspect
        if ret.is_a? _model or ret==[]
          flash[:hilite] = "wake.#{_ident}.destroy_ok"
          redirect_to :action=>'index', :id=>nil
        else
          flash.now[:error] = "wake.#{_ident}.destroy_error"
          respond_to do |format|
            format.html { raise "render_list_or_form" }
          end #render :action => _ident+'_form'
        end
      end
    end
  
  
  
    # --- private ---
  
    private
    def wake_prepare
      logger.debug "Wake PREPARE"
      @item = _model.find params[:id] if params[:id]
  #    @item ||= _model.new #params[_ident]
  #    @item ||= _model.new #params[_ident]    
    
      # @order = params[:order] if params[:order]
      # @search = params[:search] if params[:search]
    
      # @something = Something.find_by_id params[:something_id]
      for k,v in params
        if k.ends_with? "_id"
          name = k.chop.chop.chop
#          instance_variable_set "@#{name}".to_s, Class.const_get(name.camelcase).find_by_id(v)
          instance_variable_set "@#{name}".to_s, _module.const_get(name.camelcase).find_by_id(v)
        end
      end  
    end
  
    # paginate @items
    def wake_list
#      raise "#{self.class.send 'const_get', 'Elastic::Site'}"
#      raise "#{instance_eval "Elastic::Site"}"
#      raise "pizdo: #{Elastic.const_get "Site"}"
#      raise "pizdo: #{Elastic.const_get "Site"}"
      @items = _model
      @items = @items.includes _model.wake_includes if _model.respond_to? :wake_includes
    
      if params[:filter]
        for k,v in params[:filter]
          next if v.blank?
          k.gsub! /[^a-z\._]/, '' #securtity for table.row
          if ['IS TRUE','IS NOT TRUE', 'IS NULL', 'IS NOT NULL'].include? v
            @items = @items.where "#{k} #{v}"
          else
            @items = @items.where k.to_sym => v #unless v.blank?
          end
        end
      end
    
      if params[:filter_range] and !params[:filter_range][:key].blank?
        begin
          from = params[:filter_range][:from].blank? ? nil : Date.parse(params[:filter_range][:from])
        rescue ArgumentError
          from, params[:filter_range][:from_error] = nil, true
        end
        begin
          untl = params[:filter_range][:until].blank? ? nil : Date.parse(params[:filter_range][:until])
        rescue ArgumentError
          untl, params[:filter_range][:until_error] = nil, true
        end
        
        key = params[:filter_range][:key].gsub /[^a-z\+\-\._ ]/, ''
      
        if key.include? '+'
          tmp = key.split('+').map{ |x| x.strip }
          key = "DATE_ADD(#{tmp.first}, INTERVAL #{tmp.last} DAY)"
        end
        if key.include? '-'
          tmp = key.split('-').map{ |x| x.strip }
          key = "DATE_SUB(#{tmp.first}, INTERVAL #{tmp.last} DAY)"
        end
        
  #      DATE_ADD(made_out_on, INTERVAL maturity DAY)     
  #      raise key.inspect
      
        if from and untl
          @items = @items.where("? <= #{key} AND #{key} <= ?", from, (untl+1))
        elsif from
          @items = @items.where("? <= #{key}", from)
        elsif untl
          @items = @items.where("#{key} <= ?", untl+1)
        end
      end
    
      if params[:order]
        @items = @items.order(params[:order]+((params[:desc]=='true' or params[:desc]==true)  ? ' DESC' : ' ASC')) 
      end
    
      @items = @items.page(params[:page]).per(Defaults::PER_PAGE)    

      if params[:search]
        where_array = [(_model.wake_search_fields.join(" LIKE ? OR ")+' LIKE ?')] + ["%#{params[:search]}%"]*_model.wake_search_fields.size
        @items = @items.where where_array
      
        @item ||= @items.first if @items.size == 1
      end
    
      if params[:filter_ids]
        the_ids = params[:filter_ids].map { |x| x=x.to_i }
        where_array = [(" id = ? OR ")*(the_ids.size-1)+' id = ?'] + the_ids
        @items = @items.where where_array
      end
    
      # expecting model to have:
      # def wake_includes, wake_search_fields
    end
    
#    <% dom_id = dom_id(@item)+'-form' %>
  
    # def render_list_or_form
    #   if _ajax
    #     wake_list
    #     render :action => _ident+'_list'
    #   else
    #     render :action => _ident+'_form'
    #   end
    # end
  end # ClassMethods
        
end

ActionController::Base.send :extend, Wake::Extension


  # --- included ---

#   def self.included(base)
#     # # define & include session vars    
#     # base.send :define_method, :session_vars do
#     #   [:order,:search]
#     # end unless base.send :method_defined?, :session_vars
#     # 
#     # base.send :include, SessionVars
#     
#     base.send :before_filter, :wake_prepare
#     
#     # define _model and _ident ... guess form controller name
#     class_str = base.to_s.gsub(/.*::|Controller/,'').singularize    
# #    raise class_str
#     
#     # base.send :define_method, :_model do
#     #   Object.const_get class_str
#     # end unless base.send :method_defined?, :_model
#     # 
#     # base.send :define_method, :_ident do
#     #   class_str.underscore
#     # end unless base.send :method_defined?, :_ident    
#     
#     base.send :class_eval, <<-eos
#       def _model
#         #{class_str}
#       end
#       
#       def _ident
#         "#{class_str.underscore}"
#       end
#     eos
#   end    
  
#  def module
  
