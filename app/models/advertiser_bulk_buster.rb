class AdvertiserBulkBuster < Buster

  #has_attached_file :attachment

  validates   :input_filename, :task_description, :network_id, :presence => true
  validates   :input_filename, :uniqueness => true

  def bust(api_token)
    file_hash = parse_input_file(self.input_filename)
    duplicates = file_hash.select{|item| file_hash.count(item) > 1}.uniq

    puts "Duplicate Count:" + file_hash.count.to_s
    puts "Duplicate Count:" + duplicates.count.to_s
    create_advertiser_ring_pools(file_hash.uniq, api_token)
  end
end


