class AffiliatePromoNumbersController < ApplicationController
  def index
    @affiliate_promo_numbers = AffiliatePromoNumber.all
  end

  def show
    @affiliate_promo_number = AffiliatePromoNumber.find(params[:id])
  end

  def new
    @affiliate_promo_number = AffiliatePromoNumber.new
  end

  def create

    begin
      @affiliate_promo_number = AffiliatePromoNumber.new(post_params)
      puts post_params
      if params[:attachment]
        uploaded_io = params[:attachment]
        @affiliate_promo_number.input_filename =  uploaded_io.original_filename
        @affiliate_promo_number.task_description = params[:task_description].gsub!(' ','-')
      end


      if @affiliate_promo_number.save


        @affiliate_promo_number.reload
        @affiliate_promo_number.input_filename = "#{@affiliate_promo_number.task_description}--affiliate_promo_numbers--#{@affiliate_promo_number.id}.csv"
        @affiliate_promo_number.save

        redirect_to advertiser_ring_pool_bulk_busters_path #, :notice => "Your advertiser bulk has been created"
        File.open(Rails.root.join(UPLOAD_DIRECTORY, @affiliate_promo_number.input_filename), 'wb') do |file|
          file.write(uploaded_io.read)
        end

        @affiliate_promo_number.delay.bust(params[:api_token])
      else
        render "new"
      end
    end
  end

  private
  def post_params
    allow = [:network_id, :task_description, :input_filename, :request_type]
    params.require(:affiliate_promo_number).permit(allow)
  end

end
