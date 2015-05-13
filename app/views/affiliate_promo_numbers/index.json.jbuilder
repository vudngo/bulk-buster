json.array!(@affiliate_promo_numbers) do |affiliate_promo_number|
  json.extract! affiliate_promo_number, :id, :task_description, :network_id, :input_filename, :output_filename
  json.url affiliate_promo_number_url(affiliate_promo_number, format: :json)
end
