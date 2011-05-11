require 'test_helper'

class GenomesControllerTest < ActionController::TestCase
  setup do
    @genome = genomes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:genomes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create genome" do
    assert_difference('Genome.count') do
      post :create, :genome => @genome.attributes
    end

    assert_redirected_to genome_path(assigns(:genome))
  end

  test "should show genome" do
    get :show, :id => @genome.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @genome.to_param
    assert_response :success
  end

  test "should update genome" do
    put :update, :id => @genome.to_param, :genome => @genome.attributes
    assert_redirected_to genome_path(assigns(:genome))
  end

  test "should destroy genome" do
    assert_difference('Genome.count', -1) do
      delete :destroy, :id => @genome.to_param
    end

    assert_redirected_to genomes_path
  end
end
