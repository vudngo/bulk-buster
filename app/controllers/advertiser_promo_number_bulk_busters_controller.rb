class AdvertiserPromoNumberBulkBustersController < ApplicationController

  def index
    @advertiser_promo_number_bulk_busters = AdvertiserPromoNumberBulkBuster.all
  end

  def show
    @advertiser_promo_number_bulk_buster = AdvertiserPromoNumberBulkBuster.find(params[:id])
    output_hash = @advertiser_promo_number_bulk_buster.parse_output_file
    if output_hash.empty?
      @failure_count = 0
      @success_count = 0
    else
      @result_hash = @advertiser_ring_pool_bulk_buster.get_results(output_hash)
      @success_count = @result_hash["201"]
      @failure_count = output_hash.count -  @success_count
    end
  end

  def new
    @advertiser_promo_number_bulk_buster = AdvertiserPromoNumberBulkBuster.new
  end

  def create

   begin
    @advertiser_promo_number_bulk_buster = AdvertiserPromoNumberBulkBuster.new(post_params)
    puts post_params
    if params[:attachment]
     uploaded_io = params[:attachment]
     @advertiser_promo_number_bulk_buster.input_filename =  uploaded_io.original_filename
    end


    if @advertiser_promo_number_bulk_buster.save

      description = @advertiser_promo_number_bulk_buster.task_description.gsub!(/[!@%&"]/,'-')
      @advertiser_promo_number_bulk_buster.reload
      @advertiser_promo_number_bulk_buster.input_filename = "#{description}--advertiser_promo_number_bulk_input--#{@advertiser_promo_number_bulk_buster.id}.csv"
      @advertiser_promo_number_bulk_buster.save

      redirect_to advertiser_ring_pool_bulk_busters_path #, :notice => "Your advertiser bulk has been created"
      File.open(Rails.root.join(UPLOAD_DIRECTORY, @advertiser_promo_number_bulk_buster.input_filename), 'wb') do |file|
         file.write(uploaded_io.read)
      end

        @advertiser_promo_number_bulk_buster.delay.bust(params[:api_token])
    else
      render "new"
    end
   end
  end

  private
  def post_params
    allow = [:network_id, :task_description, :input_filename, :request_type]
    params.require(:advertiser_promo_number_bulk_buster).permit(allow)
  end
  
end
