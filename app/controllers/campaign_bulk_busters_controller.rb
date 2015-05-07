class CampaignBulkBustersController < ApplicationController

  def index
    @campaign_bulk_busters = CampaignBulkBuster.all
  end

  def show
    @campaign_bulk_buster = CampaignBulkBuster.find(params[:id])
    output_hash = @campaign_bulk_buster.parse_output_file
    if output_hash.empty?
      @success_count = 0
      @failure_count = 0
    else
      @result_hash = @campaign_bulk_buster.get_results(output_hash)
      @success_count = @result_hash["201"]
      @failure_count = output_hash.count -  @success_count
    end
  end

  def new
    @campaign_bulk_buster = CampaignBulkBuster.new
  end

  def create
    @campaign_bulk_buster = CampaignBulkBuster.new(post_params)

    if params[:attachment]
      uploaded_io = params[:attachment]
      @campaign_bulk_buster.input_filename =  uploaded_io.original_filename
    end

    if @campaign_bulk_buster.save
      @campaign_bulk_buster.reload
      @campaign_bulk_buster.input_filename = "#{@campaign_bulk_buster.task_description.gsub!(/[!@%&"]/,'-')}--campaign_bulk_input--#{@campaign_bulk_buster.id}.csv"
      @campaign_bulk_buster.save
      redirect_to campaign_bulk_busters_path #, :notice => "Your campaign bulk has been created"
      File.open(Rails.root.join(UPLOAD_DIRECTORY, @campaign_bulk_buster.input_filename), 'wb') do |file|
        file.write(uploaded_io.read)
      end
      @campaign_bulk_buster.delay.bust(params[:api_token])
    else
      render "new"
    end

  end

  def edit
    @campaign_bulk_buster = CampaignBulkBuster.find(params[:id])
  end

  def update
    @campaign_bulk_buster = CampaignBulkBuster.find(params[:id])

    if @campaign_bulk_buster.update_attributes(post_params)
      redirect_to campaign_bulk_busters_path, :notice => "Your campaign bulk has been updated"
    else
      render "edit"
    end
  end

  def destroy
    @campaign_bulk_buster = CampaignBulkBuster.find(params[:id])
    @campaign_bulk_buster.destroy
    redirect_to campaign_bulk_busters_path, :notice => "Your campaign bulk has been deleted"
  end


  def download
    send_file "#{RAILS_ROOT}/#{params[:file_name]}"
  end

  private
  def post_params
    allow = [:network_id, :task_description, :input_filename, :advertiser_id_from_network_to_clone, :campaign_id_from_network_to_clone]
    params.require(:campaign_bulk_buster).permit(allow)
  end


end
