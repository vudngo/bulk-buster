class BulkTrackersController < ApplicationController
  def index
    @bulk_trackers              = BulkTracker.all
    @advertiser_total           = @bulk_trackers.map {|b| b.advertiser_count}.compact.inject(0, :+)
    @advertiser_campaign_total  = @bulk_trackers.map {|b| b.advertiser_campaign_count}.compact.inject(0, :+)
    @affiliate_total            = @bulk_trackers.map {|b| b.affiliate_count}.compact.inject(0, :+)
    @affiliate_campaign_total   = @bulk_trackers.map {|b| b.affiliate_campaign_count}.compact.inject(0, :+)
    @ring_pool_total            = @bulk_trackers.map {|b| b.ring_pool_count}.compact.inject(0, :+)
    @promo_number_total         = @bulk_trackers.map {|b| b.promo_number_count}.compact.inject(0, :+)
  end

  def show
    @bulk_tracker = BulkTracker.find(params[:id])
  end

  def new
    head 403
  end

  def create
    head 403
  end

  def edit
    head 403
  end

  def update
    head 403
  end

  def destroy
    head 403
  end
  private

  def post_params
    allow = []
    params.require(:bulk_tracker).permit(allow)
  end
  
  
  
end
