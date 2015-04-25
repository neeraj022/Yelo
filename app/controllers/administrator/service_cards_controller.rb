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
                return ServiceCard::SERVICE_CARD[:HIDDEN]
            when "reject"
                return ServiceCard::SERVICE_CARD[:REJECT]
            else
                ServiceCard::SERVICE_CARD[:ON]
            end
      return status
  end

  def update
     @service_card = ServiceCard.find(params[:id])
     respond_to do |format|
       if(@service_card.update_attributes(service_card_params))
         if(@service_card.status == ServiceCard::SERVICE_CARD[:REJECT])
           send_reject_message
         end
         format.html { redirect_to [:administrator, @service_card]}
       else
       	format.html {render :edit}
       end
     end
  end

  def send_reject_message
    num = Rails.application.secrets.w_mobile_number
    num = User.mobile_number_format(num) 
    yelo = User.where(mobile_number: num[:mobile_number]).first
    User.send_chat_message(yelo, @service_card.user, @service_card.message)
  end
  
  private

  def service_card_params
    params.require(:service_card).permit(:message, :status)
  end
end
