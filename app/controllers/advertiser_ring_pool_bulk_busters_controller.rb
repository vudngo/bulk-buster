class AdvertiserRingPoolBulkBustersController < ApplicationController

  def index
    @advertiser_ring_pool_bulk_busters = AdvertiserRingPoolBulkBuster.all
  end

  def show
    @advertiser_ring_pool_bulk_buster = AdvertiserRingPoolBulkBuster.find(params[:id])
    output_hash = @advertiser_ring_pool_bulk_buster.parse_output_file
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
    @advertiser_ring_pool_bulk_buster = AdvertiserRingPoolBulkBuster.new
  end

  def create
    @advertiser_ring_pool_bulk_buster = AdvertiserRingPoolBulkBuster.new(post_params)

    if params[:attachment]
      uploaded_io = params[:attachment]
      @advertiser_ring_pool_bulk_buster.input_filename =  uploaded_io.original_filename
    end

    if @advertiser_ring_pool_bulk_buster.save
      @advertiser_ring_pool_bulk_buster.reload
      @advertiser_ring_pool_bulk_buster.input_filename = "#{@advertiser_ring_pool_bulk_buster.task_description.gsub!(/[!@%&"]/,'-')}--advertiser_ring_pool_bulk_input--#{@advertiser_ring_pool_bulk_buster.id}.csv"
      @advertiser_ring_pool_bulk_buster.save
      redirect_to advertiser_ring_pool_bulk_busters_path #, :notice => "Your advertiser bulk has been created"
      File.open(Rails.root.join(UPLOAD_DIRECTORY, @advertiser_ring_pool_bulk_buster.input_filename), 'wb') do |file|
        file.write(uploaded_io.read)
      end
      @advertiser_ring_pool_bulk_buster.bust(params[:api_token])
    else
      render "new"
    end
  end

  def edit
    @advertiser_ring_pool_bulk_buster = AdvertiserRingPoolBulkBuster.find(params[:id])
  end

  def update
    @advertiser_ring_pool_bulk_buster = AdvertiserRingPoolBulkBuster.find(params[:id])

    if @advertiser_ring_pool_bulk_buster.update_attributes(post_params)
      redirect_to advertiser_ring_pool_bulk_busters_path, :notice => "Your advertiser bulk has been updated"
    else
      render "edit"
    end
  end

  def destroy
    @advertiser_ring_pool_bulk_buster = AdvertiserRingPoolBulkBuster.find(params[:id])
    @advertiser_ring_pool_bulk_buster.destroy
    redirect_to advertiser_ring_pool_bulk_busters_path, :notice => "Your advertiser bulk has been deleted"
  end
  private

  def post_params
    allow = [:network_id, :task_description, :input_filename ]
    params.require(:advertiser_ring_pool_bulk_buster).permit(allow)
  end

end
