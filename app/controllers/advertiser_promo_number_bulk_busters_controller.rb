class AdvertiserPromoNumberBulkBustersController < ApplicationController

  def new
    @advertiser_promo_number_bulk_buster = AdvertiserRingPoolBulkBuster.new
  end

  def create
   begin
    @advertiser_promo_number_bulk_buster = AdvertiserPromoNumberBulkBuster.new(post_params)
    puts post_params
   # if params[:attachment]
     # uploaded_io = params[:attachment]
    #  @advertiser_promo_number_bulk_buster.input_filename =  uploaded_io.original_filename
   # end


   # if @advertiser_promo_number_bulk_buster.save
    #  @advertiser_promo_number_bulk_buster.reload
    #  @advertiser_promo_number_bulk_buster.input_filename = "advertiser_bulk_#{@advertiser_promo_number_bulk_buster.id}.csv"
    #  @advertiser_promo_number_bulk_buster.save
      #redirect_to advertiser_ring_pool_bulk_busters_path #, :notice => "Your advertiser bulk has been created"
    #  File.open(Rails.root.join(UPLOAD_DIRECTORY, @advertiser_promo_number_bulk_buster.input_filename), 'wb') do |file|
    #    file.write(uploaded_io.read)
    #  end
      #@advertiser_promo_number_bulk_buster.bust(params[:api_token])
   # else
    #  render "new"
   # end
   end
  end

  private
  def post_params
    allow = [:network_id, :task_description, :input_filename, :request_type]
    params.require(:advertiser_promo_number_bulk_buster).permit(allow)
  end
  
end