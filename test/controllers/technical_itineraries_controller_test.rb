require 'test_helper'

class TechnicalItinerariesControllerTest < ActionController::TestCase
  setup do
    @technical_itinerary = technical_itineraries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:technical_itineraries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create technical_itinerary" do
    assert_difference('TechnicalItinerary.count') do
      post :create, technical_itinerary: {  }
    end

    assert_redirected_to technical_itinerary_path(assigns(:technical_itinerary))
  end

  test "should show technical_itinerary" do
    get :show, id: @technical_itinerary
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @technical_itinerary
    assert_response :success
  end

  test "should update technical_itinerary" do
    patch :update, id: @technical_itinerary, technical_itinerary: {  }
    assert_redirected_to technical_itinerary_path(assigns(:technical_itinerary))
  end

  test "should destroy technical_itinerary" do
    assert_difference('TechnicalItinerary.count', -1) do
      delete :destroy, id: @technical_itinerary
    end

    assert_redirected_to technical_itineraries_path
  end
end
