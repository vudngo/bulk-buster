class AffiliateCampaignBulkBustersController < ApplicationController

  def index
    @affiliate_campaign_bulk_busters = AffiliateCampaignBulkBuster.all
  end

  def show
    @affiliate_campaign_bulk_buster = AffiliateCampaignBulkBuster.find(params[:id])
    output_hash = @affiliate_campaign_bulk_buster.parse_output_file
    if !output_hash.empty?
      @result_hash = @affiliate_campaign_bulk_buster.get_results(output_hash)
      @success_count = @result_hash["201"]
      puts output_hash
      puts @success_count
      @failure_count = output_hash.count -  @success_count
    else
      @result_hash = @affiliate_campaign_bulk_buster.get_results(output_hash)
      @success_count = 0
      @success_count = 0
      @failure_count = 0
    end
  end

  def new
    @affiliate_campaign_bulk_buster = AffiliateCampaignBulkBuster.new
  end

  def create
    @affiliate_campaign_bulk_buster = AffiliateCampaignBulkBuster.new(post_params)

    if params[:attachment]
      uploaded_io = params[:attachment]
      @affiliate_campaign_bulk_buster.input_filename =  uploaded_io.original_filename
    end

    if @affiliate_campaign_bulk_buster.save
      @affiliate_campaign_bulk_buster.reload
      @affiliate_campaign_bulk_buster.input_filename = "#{@affiliate_campaign_bulk_buster.task_description.gsub!(/[!@%&"]/,'-')}--affiliate_campaign_bulk_input--#{@affiliate_campaign_bulk_buster.id}.csv"
      @affiliate_campaign_bulk_buster.save
      redirect_to affiliate_campaign_bulk_busters_path #, :notice => "Your affiliate_campaign bulk has been created"
      File.open(Rails.root.join(UPLOAD_DIRECTORY, @affiliate_campaign_bulk_buster.input_filename), 'wb') do |file|
        file.write(uploaded_io.read)
      end
      @affiliate_campaign_bulk_buster.bust(params[:api_token])
    else
      render "new"
    end
  end

  def edit
    @affiliate_campaign_bulk_buster = AffiliateCampaignBulkBuster.find(params[:id])
  end

  def update
    @affiliate_campaign_bulk_buster = AffiliateCampaignBulkBuster.find(params[:id])

    if @affiliate_campaign_bulk_buster.update_attributes(post_params)
      redirect_to affiliate_campaign_bulk_busters_path, :notice => "Your affiliate campaign bulk has been updated"
    else
      render "edit"
    end
  end

  def destroy
    @affiliate_campaign_bulk_buster = AffiliateCampaignBulkBuster.find(params[:id])
    @affiliate_campaign_bulk_buster.destroy
    redirect_to affiliate_campaign_bulk_busters_path, :notice => "Your affiliate campaign bulk has been deleted"
  end
  private

  def post_params
    allow = [:network_id, :task_description, :input_filename ]
    params.require(:affiliate_campaign_bulk_buster).permit(allow)
  end

end
