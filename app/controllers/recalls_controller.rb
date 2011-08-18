class RecallsController < ApplicationController
  # Filter
  has_scope :by_period, :using => [:from, :to]

  # GET /recalls
  def index
    @scheduled_recalls = apply_scopes(Recall).queued.paginate(:page => params['page'], :order => 'due_date')
    @sent_recalls = apply_scopes(Recall).sent.paginate(:page => params['page'], :order => 'due_date')
  end
  
  # GET /patients/1/recalls/new
  def new
    @patient = Patient.find(params[:patient_id])
    @recall  = @patient.recalls.build

    respond_to do |format|
      format.html { }
      format.js {
        render :update do |page|
          page.replace_html "new_recall", :partial => 'form'
          page.call(:initBehaviour)
        end
      }
    end
  end

  # PUT /patients/1/recall
  def create
    @patient = Patient.find(params[:patient_id])
    @recall  = @patient.recalls.build(params[:recall])
    
    # Should be handled by model
    # @recall.appointment.patient = @recall.patient
    # @recall.appointment.state = 'proposed'
    
    if @recall.save
      respond_to do |format|
        format.html { }
        format.js {
          render :update do |page|
            page.replace_html 'patient_recalls', :partial => 'recalls/patient_item', :collection => @patient.recalls.open
            page.replace_html 'new_recall'
          end
        }
      end
    else
      respond_to do |format|
        format.html { }
        format.js {
          render :update do |page|
            page.replace 'recall_form', :partial => 'recalls/form', :object => @recall
            page.call(:initBehaviour)
          end
        }
      end
    end
  end

  # GET /recall/1/edit
  def edit
    @patient = Patient.find(params[:patient_id]) if params[:patient_id]
    @recall = Recall.find(params[:id])
    
    respond_to do |format|
      format.html { }
      format.js {
        render :update do |page|
          page.insert_html :after, "recall_#{@recall.id}", :partial => 'recalls/form'
          page.call(:initBehaviour)
        end
      }
    end
  end
  
  # PUT /recall/1
  # PUT /patients/1/recall/2
  def update
    @patient = Patient.find(params[:patient_id]) if params[:patient_id]
    @recall = Recall.find(params[:id])
    
    if @recall.update_attributes(params[:recall])
      if params['send_notice']
        @recall.send_notice
        @recall.save
        
        render :update do |page|
          page.remove "recall_form"
          page.redirect_to :action => 'show', :format => :pdf
        end
        return
      end
      respond_to do |format|
        format.html { }
        format.js {
          render :update do |page|
            if @patient
              # reload all recalls when called in patient view to reflect sorting
              page.replace_html 'recalls', :partial => 'recalls/patient_item', :collection => @patient.recalls.open
            else
              page.replace "recall_#{@recall.id}", :partial => 'item', :object => @recall
              page.remove "recall_form"
            end
          end
        }
      end
    else
      respond_to do |format|
        format.html { }
        format.js {
          render :update do |page|
            page.replace 'recall_form', :partial => 'recalls/form'
            page.call(:initBehaviour)
          end
        }
      end
    end
  end

  # POST /recall/1/prepare
  def prepare
    @recall = Recall.find(params[:id])
    @recall.prepare
    
    unless @recall.appointment
      @recall.build_appointment(:patient => @recall.patient)
    end

    respond_to do |format|
      format.html { }
      format.js {
        render :update do |page|
          page.insert_html :after, "recall_#{@recall.id}", :partial => 'recalls/form'
        end
      }
    end
  end

  # POST /recall/1/send
  def send_notice
    @recall = Recall.find(params[:id])
    @recall.send_notice
    @recall.save
    
    respond_to do |format|
      format.html { }
      format.js {
        render :update do |page|
          page.remove "recall_form"
          page.redirect_to :action => 'show', :format => :pdf
        end
      }
    end
  end
  
  # POST /recall/1/obey
  def obey
    @recall = Recall.find(params[:id])
    @patient = @recall.patient
    @recall.obey
    @recall.save
    
    @old_recall = @recall
    @recall = @old_recall.patient.recalls.build
    @recall.remarks = @old_recall.remarks
    last_session = @old_recall.patient.last_session
    next_due_date = last_session.nil? ? Date.today.in(1.year) : last_session.duration_from.in(1.year)
    @recall.due_date = next_due_date.to_date
    
    respond_to do |format|
      format.html { }
      format.js {
        render :update do |page|
          page.insert_html :after, "recall_#{@old_recall.id}", :partial => 'form'
          page.remove "recall_#{@old_recall.id}"
        end
      }
    end
  end
  
  # DELETE /recall/1
  def destroy
    @recall = Recall.find(params[:id])
    @recall.destroy
    
    respond_to do |format|
      format.html { }
      format.js {
        render :update do |page|
          page.remove "recall_#{@recall.id}"
        end
      }
    end
  end

  # GET /patients/1/recalls/1
  def show
    @recall  = Recall.find(params[:id])
    @patient = @recall.patient

    respond_to do |format|
      format.pdf {
        render :layout => false
      }
    end
  end
end
