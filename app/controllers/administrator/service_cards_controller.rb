class Administrator::ServiceCardsController < Administrator::AdministratorController
  
  def index
    if params[:status].present?
    	@service_cards = ServiceCard.where(status: status_param).page(params[:page]).per(30)
    else
      @service_cards = ServiceCard.all.page(params[:page]).per(30)
    end
  end

  def edit
    @service_card = ServiceCard.find(params[:id])
  end

  def show
    @service_card = ServiceCard.find(params[:id])
    @user = @service_card.user
  end

  def status_param
    status = case params[:status].downcase
             when "on"
                return ServiceCard::SERVICE_CARD[:ON]
             when "off"
                return ServiceCard::SERVICE_CARD[:OFF]
              when "hidden"
                return ServiceCard::SERVICE_CARD[:OFF]
              else
                 ServiceCard::SERVICE_CARD[:ON]
              end
      return status
  end

  def update
     @service_card = ServiceCard.find(params[:id])
     respond_to do |format|
       if(@service_card.update_attributes(service_card_params))
         format.html { redirect_to [:administrator, @service_card]}
       else
       	format.html {render :edit}
       end
     end
  end
  
  private

  def service_card_params
    params.require(:service_card).permit(:message, :status)
  end
end
