class AdvertiserBulkBustersController < ApplicationController

  def index
    @advertiser_bulk_busters = AdvertiserBulkBuster.all
  end

  def show
    @advertiser_bulk_buster = AdvertiserBulkBuster.find(params[:id])
  end

  def new
    @advertiser_bulk_buster = AdvertiserBulkBuster.new
  end

  def create
    @advertiser_bulk_buster = AdvertiserBulkBuster.new(post_params)

    if params[:attachment]
      uploaded_io = params[:attachment]
      @advertiser_bulk_buster.input_filename =  uploaded_io.original_filename
    end

    if @advertiser_bulk_buster.save
      @advertiser_bulk_buster.reload
      @advertiser_bulk_buster.input_filename = "advertiser_ring_pool_bulk_#{@advertiser_bulk_buster.id}.csv"
      @advertiser_bulk_buster.save
      redirect_to advertiser_bulk_busters_path #, :notice => "Your advertiser bulk has been created"
      File.open(Rails.root.join(UPLOAD_DIRECTORY, @advertiser_bulk_buster.input_filename), 'wb') do |file|
        file.write(uploaded_io.read)
      end
      @advertiser_bulk_buster.delay.bust(params[:api_token])
      @advertiser_bulk_buster.create_bulk_tracker
    else
      render "new"
    end
  end

  def edit
    @advertiser_bulk_buster = AdvertiserBulkBuster.find(params[:id])
  end

  def update
    @advertiser_bulk_buster = AdvertiserBulkBuster.find(params[:id])

    if @advertiser_bulk_buster.update_attributes(post_params)
      redirect_to advertiser_bulk_busters_path, :notice => "Your advertiser bulk has been updated"
    else
      render "edit"
    end
  end

  def destroy
    @advertiser_bulk_buster = AdvertiserBulkBuster.find(params[:id])
    @advertiser_bulk_buster.destroy
    redirect_to advertiser_bulk_busters_path, :notice => "Your advertiser bulk has been deleted"
  end
  private

  def post_params
    allow = [:network_id, :task_description, :input_filename ]
    params.require(:advertiser_bulk_buster).permit(allow)
  end

end
