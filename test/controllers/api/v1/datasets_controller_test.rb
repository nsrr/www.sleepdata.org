# frozen_string_literal: true

require "test_helper"

# Tests to assure that users can view list of available datasets and files.
class Api::V1::DatasetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dataset = datasets(:released)
  end

  test "should get index" do
    get api_v1_datasets_url(format: "json")
    assert_response :success
  end

  test "should get show" do
    get api_v1_dataset_url(@dataset, format: "json")
    assert_response :success
  end

  test "should get index as json" do
    get api_v1_datasets_url(format: "json")
    assert_not_nil assigns(:datasets)
    datasets = JSON.parse(response.body)
    assert_equal 1, datasets.select { |d| d["slug"] == "released" }.count
    assert_equal 0, datasets.select { |d| d["slug"] == "unreleased" }.count
    assert_response :success
  end

  test "should get index as json for user with token" do
    get api_v1_datasets_url(format: "json"), params: { auth_token: users(:admin).id_and_auth_token }
    assert_not_nil assigns(:datasets)
    datasets = JSON.parse(response.body)
    assert_equal 1, datasets.select { |d| d["slug"] == "released" }.count
    assert_equal 1, datasets.select { |d| d["slug"] == "unreleased" }.count
    assert_response :success
  end

  test "should show public dataset to logged out user as json" do
    get api_v1_dataset_url(@dataset, format: "json")
    dataset = JSON.parse(response.body)
    assert_equal "We Care", dataset["name"]
    assert_equal "released", dataset["slug"]
    assert_not_nil dataset["created_at"]
    assert_not_nil dataset["updated_at"]
    assert_response :success
  end

  test "should show unreleased dataset to authorized user with token" do
    get api_v1_dataset_url(datasets(:unreleased), format: "json"), params: {
      auth_token: users(:admin).id_and_auth_token
    }
    assert_not_nil assigns(:dataset)
    dataset = JSON.parse(response.body)
    assert_equal "unreleased", dataset["slug"]
    assert_equal "In the Works", dataset["name"]
    assert_response :success
  end

  test "should get files for single file using auth token" do
    get files_api_v1_dataset_url(
      @dataset,
      path: "subfolder/1.txt",
      auth_token: users(:valid).id_and_auth_token,
      format: "json"
    )
    manifest = JSON.parse(response.body)
    assert_equal 1, manifest.size
    assert_equal "released", manifest[0]["dataset"]
    assert_equal "subfolder/1.txt", manifest[0]["full_path"]
    assert_equal "subfolder/", manifest[0]["folder"]
    assert_equal "1.txt", manifest[0]["file_name"]
    assert_equal true, manifest[0]["is_file"]
    assert_equal 6, manifest[0]["file_size"]
    assert_equal "39061daa34ca3de20df03a88c52530ea", manifest[0]["file_checksum_md5"]
    assert_equal false, manifest[0]["archived"]
    assert_response :success
  end

  test "should get files folder using auth token" do
    get files_api_v1_dataset_url(
      @dataset,
      path: "subfolder",
      auth_token: users(:valid).id_and_auth_token,
      format: "json"
    )
    manifest = JSON.parse(response.body)
    assert_equal 5, manifest.size
    assert_equal "released", manifest[0]["dataset"]
    assert_equal "subfolder/another_folder", manifest[0]["full_path"]
    assert_equal "subfolder/", manifest[0]["folder"]
    assert_equal "another_folder", manifest[0]["file_name"]
    assert_equal false, manifest[0]["is_file"]
    assert_equal 102, manifest[0]["file_size"]
    assert_nil manifest[0]["file_checksum_md5"]
    assert_equal false, manifest[0]["archived"]
    assert_equal "released", manifest[1]["dataset"]
    assert_equal "subfolder/1.txt", manifest[1]["full_path"]
    assert_equal "subfolder/", manifest[1]["folder"]
    assert_equal "1.txt", manifest[1]["file_name"]
    assert_equal true, manifest[1]["is_file"]
    assert_equal 6, manifest[1]["file_size"]
    assert_equal "39061daa34ca3de20df03a88c52530ea", manifest[1]["file_checksum_md5"]
    assert_equal false, manifest[1]["archived"]
    assert_equal "released", manifest[2]["dataset"]
    assert_equal "subfolder/2.txt", manifest[2]["full_path"]
    assert_equal "subfolder/", manifest[2]["folder"]
    assert_equal "2.txt", manifest[2]["file_name"]
    assert_equal true, manifest[2]["is_file"]
    assert_equal 6, manifest[2]["file_size"]
    assert_equal "85c8f17e86771eb8480a44349e13127b", manifest[2]["file_checksum_md5"]
    assert_equal false, manifest[2]["archived"]
    assert_equal "released", manifest[3]["dataset"]
    assert_equal "subfolder/IN_SUBFOLDER_NOT_PUBLIC_YET.txt", manifest[3]["full_path"]
    assert_equal "subfolder/", manifest[3]["folder"]
    assert_equal "IN_SUBFOLDER_NOT_PUBLIC_YET.txt", manifest[3]["file_name"]
    assert_equal true, manifest[3]["is_file"]
    assert_equal 32, manifest[3]["file_size"]
    assert_equal "8a59dbfe009557d80a3467acbe141d65", manifest[3]["file_checksum_md5"]
    assert_equal false, manifest[3]["archived"]
    assert_equal "released", manifest[4]["dataset"]
    assert_equal "subfolder/IN_SUBFOLDER_PUBLIC_FILE.txt", manifest[4]["full_path"]
    assert_equal "subfolder/", manifest[4]["folder"]
    assert_equal "IN_SUBFOLDER_PUBLIC_FILE.txt", manifest[4]["file_name"]
    assert_equal true, manifest[4]["is_file"]
    assert_equal 29, manifest[4]["file_size"]
    assert_equal "29423ee86b07cb966ea263a37e88669a", manifest[4]["file_checksum_md5"]
    assert_equal false, manifest[4]["archived"]
    assert_response :success
  end

  test "should get files with blank path using auth token" do
    get files_api_v1_dataset_url(
      @dataset,
      path: "",
      auth_token: users(:valid).id_and_auth_token,
      format: "json"
    )
    manifest = JSON.parse(response.body)
    assert_equal 6, manifest.size
    assert_equal "released", manifest[0]["dataset"]
    assert_equal "previews", manifest[0]["full_path"]
    assert_equal "", manifest[0]["folder"]
    assert_equal "previews", manifest[0]["file_name"]
    assert_equal false, manifest[0]["is_file"]
    assert_equal 160, manifest[0]["file_size"]
    assert_nil manifest[0]["file_checksum_md5"]
    assert_equal false, manifest[0]["archived"]
    assert_equal "released", manifest[1]["dataset"]
    assert_equal "subfolder", manifest[1]["full_path"]
    assert_equal "", manifest[1]["folder"]
    assert_equal "subfolder", manifest[1]["file_name"]
    assert_equal false, manifest[1]["is_file"]
    assert_equal 204, manifest[1]["file_size"]
    assert_nil manifest[1]["file_checksum_md5"]
    assert_equal false, manifest[1]["archived"]
    assert_equal "released", manifest[2]["dataset"]
    assert_equal "ACCESS_REQUIRED.txt", manifest[2]["full_path"]
    assert_equal "", manifest[2]["folder"]
    assert_equal "ACCESS_REQUIRED.txt", manifest[2]["file_name"]
    assert_equal true, manifest[2]["is_file"]
    assert_equal 20, manifest[2]["file_size"]
    assert_equal "26b1203ed43bcf15e89dcb2e79b804b8", manifest[2]["file_checksum_md5"]
    assert_equal false, manifest[2]["archived"]
    assert_equal "released", manifest[3]["dataset"]
    assert_equal "DOWNLOAD_ME.txt", manifest[3]["full_path"]
    assert_equal "", manifest[3]["folder"]
    assert_equal "DOWNLOAD_ME.txt", manifest[3]["file_name"]
    assert_equal true, manifest[3]["is_file"]
    assert_equal 16, manifest[3]["file_size"]
    assert_equal "be3aad0b46648b4867534a1b10ec6ed1", manifest[3]["file_checksum_md5"]
    assert_equal false, manifest[3]["archived"]
    assert_equal "released", manifest[4]["dataset"]
    assert_equal "NOT_PUBLIC_YET.txt", manifest[4]["full_path"]
    assert_equal "", manifest[4]["folder"]
    assert_equal "NOT_PUBLIC_YET.txt", manifest[4]["file_name"]
    assert_equal true, manifest[4]["is_file"]
    assert_equal 19, manifest[4]["file_size"]
    assert_equal "b9ec2f286c32a9056dc00580c586dd37", manifest[4]["file_checksum_md5"]
    assert_equal false, manifest[4]["archived"]
    assert_equal "released", manifest[5]["dataset"]
    assert_equal "PUBLIC_FILE.txt", manifest[5]["full_path"]
    assert_equal "", manifest[5]["folder"]
    assert_equal "PUBLIC_FILE.txt", manifest[5]["file_name"]
    assert_equal true, manifest[5]["is_file"]
    assert_equal 16, manifest[5]["file_size"]
    assert_equal "41621f39d8ac658105c84cba3a94ebc8", manifest[5]["file_checksum_md5"]
    assert_equal false, manifest[5]["archived"]
    assert_response :success
  end

  test "should get files with nil path using auth token" do
    get files_api_v1_dataset_url(
      @dataset,
      auth_token: users(:valid).id_and_auth_token,
      format: "json"
    )
    manifest = JSON.parse(response.body)
    assert_equal 6, manifest.size
    assert_equal "released", manifest[0]["dataset"]
    assert_equal "previews", manifest[0]["full_path"]
    assert_equal "", manifest[0]["folder"]
    assert_equal "previews", manifest[0]["file_name"]
    assert_equal false, manifest[0]["is_file"]
    assert_equal 160, manifest[0]["file_size"]
    assert_nil manifest[0]["file_checksum_md5"]
    assert_equal false, manifest[0]["archived"]
    assert_equal "released", manifest[1]["dataset"]
    assert_equal "subfolder", manifest[1]["full_path"]
    assert_equal "", manifest[1]["folder"]
    assert_equal "subfolder", manifest[1]["file_name"]
    assert_equal false, manifest[1]["is_file"]
    assert_equal 204, manifest[1]["file_size"]
    assert_nil manifest[1]["file_checksum_md5"]
    assert_equal false, manifest[1]["archived"]
    assert_equal "released", manifest[2]["dataset"]
    assert_equal "ACCESS_REQUIRED.txt", manifest[2]["full_path"]
    assert_equal "", manifest[2]["folder"]
    assert_equal "ACCESS_REQUIRED.txt", manifest[2]["file_name"]
    assert_equal true, manifest[2]["is_file"]
    assert_equal 20, manifest[2]["file_size"]
    assert_equal "26b1203ed43bcf15e89dcb2e79b804b8", manifest[2]["file_checksum_md5"]
    assert_equal false, manifest[2]["archived"]
    assert_equal "released", manifest[3]["dataset"]
    assert_equal "DOWNLOAD_ME.txt", manifest[3]["full_path"]
    assert_equal "", manifest[3]["folder"]
    assert_equal "DOWNLOAD_ME.txt", manifest[3]["file_name"]
    assert_equal true, manifest[3]["is_file"]
    assert_equal 16, manifest[3]["file_size"]
    assert_equal "be3aad0b46648b4867534a1b10ec6ed1", manifest[3]["file_checksum_md5"]
    assert_equal false, manifest[3]["archived"]
    assert_equal "released", manifest[4]["dataset"]
    assert_equal "NOT_PUBLIC_YET.txt", manifest[4]["full_path"]
    assert_equal "", manifest[4]["folder"]
    assert_equal "NOT_PUBLIC_YET.txt", manifest[4]["file_name"]
    assert_equal true, manifest[4]["is_file"]
    assert_equal 19, manifest[4]["file_size"]
    assert_equal "b9ec2f286c32a9056dc00580c586dd37", manifest[4]["file_checksum_md5"]
    assert_equal false, manifest[4]["archived"]
    assert_equal "released", manifest[5]["dataset"]
    assert_equal "PUBLIC_FILE.txt", manifest[5]["full_path"]
    assert_equal "", manifest[5]["folder"]
    assert_equal "PUBLIC_FILE.txt", manifest[5]["file_name"]
    assert_equal true, manifest[5]["is_file"]
    assert_equal 16, manifest[5]["file_size"]
    assert_equal "41621f39d8ac658105c84cba3a94ebc8", manifest[5]["file_checksum_md5"]
    assert_equal false, manifest[5]["archived"]
    assert_response :success
  end

  test "should not get unreleased manifest for unapproved user using auth token" do
    get files_api_v1_dataset_url(
      datasets(:unreleased),
      auth_token: users(:valid).id_and_auth_token,
      format: "json"
    )
    assert_template nil
    assert_response :success
  end
end
