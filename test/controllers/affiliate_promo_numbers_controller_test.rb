require 'test_helper'

class AffiliatePromoNumbersControllerTest < ActionController::TestCase
  setup do
    @affiliate_promo_number = affiliate_promo_numbers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:affiliate_promo_numbers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create affiliate_promo_number" do
    assert_difference('AffiliatePromoNumber.count') do
      post :create, affiliate_promo_number: { input_filename: @affiliate_promo_number.input_filename, network_id: @affiliate_promo_number.network_id, output_filename: @affiliate_promo_number.output_filename, task_description: @affiliate_promo_number.task_description }
    end

    assert_redirected_to affiliate_promo_number_path(assigns(:affiliate_promo_number))
  end

  test "should show affiliate_promo_number" do
    get :show, id: @affiliate_promo_number
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @affiliate_promo_number
    assert_response :success
  end

  test "should update affiliate_promo_number" do
    patch :update, id: @affiliate_promo_number, affiliate_promo_number: { input_filename: @affiliate_promo_number.input_filename, network_id: @affiliate_promo_number.network_id, output_filename: @affiliate_promo_number.output_filename, task_description: @affiliate_promo_number.task_description }
    assert_redirected_to affiliate_promo_number_path(assigns(:affiliate_promo_number))
  end

  test "should destroy affiliate_promo_number" do
    assert_difference('AffiliatePromoNumber.count', -1) do
      delete :destroy, id: @affiliate_promo_number
    end

    assert_redirected_to affiliate_promo_numbers_path
  end
end
