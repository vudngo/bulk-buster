class AffiliatePromoNumbersController < ApplicationController
  before_action :set_affiliate_promo_number, only: [:show, :edit, :update, :destroy]

  # GET /affiliate_promo_numbers
  # GET /affiliate_promo_numbers.json
  def index
    @affiliate_promo_numbers = AffiliatePromoNumber.all
  end

  # GET /affiliate_promo_numbers/1
  # GET /affiliate_promo_numbers/1.json
  def show
  end

  # GET /affiliate_promo_numbers/new
  def new
    @affiliate_promo_number = AffiliatePromoNumber.new
  end

  # GET /affiliate_promo_numbers/1/edit
  def edit
  end

  # POST /affiliate_promo_numbers
  # POST /affiliate_promo_numbers.json
  def create
    @affiliate_promo_number = AffiliatePromoNumber.new(affiliate_promo_number_params)

    respond_to do |format|
      if @affiliate_promo_number.save
        format.html { redirect_to @affiliate_promo_number, notice: 'Affiliate promo number was successfully created.' }
        format.json { render :show, status: :created, location: @affiliate_promo_number }
      else
        format.html { render :new }
        format.json { render json: @affiliate_promo_number.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /affiliate_promo_numbers/1
  # PATCH/PUT /affiliate_promo_numbers/1.json
  def update
    respond_to do |format|
      if @affiliate_promo_number.update(affiliate_promo_number_params)
        format.html { redirect_to @affiliate_promo_number, notice: 'Affiliate promo number was successfully updated.' }
        format.json { render :show, status: :ok, location: @affiliate_promo_number }
      else
        format.html { render :edit }
        format.json { render json: @affiliate_promo_number.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /affiliate_promo_numbers/1
  # DELETE /affiliate_promo_numbers/1.json
  def destroy
    @affiliate_promo_number.destroy
    respond_to do |format|
      format.html { redirect_to affiliate_promo_numbers_url, notice: 'Affiliate promo number was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_affiliate_promo_number
      @affiliate_promo_number = AffiliatePromoNumber.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def affiliate_promo_number_params
      params.require(:affiliate_promo_number).permit(:task_description, :network_id, :input_filename, :output_filename)
    end
end
