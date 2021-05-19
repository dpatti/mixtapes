class ContestsController < ApplicationController
  def index
    @contests = Contest.order(:start_date)
  end

  def download
    contest = Contest.find(params[:id])
    mixtapes = contest.mixtapes.with_songs
    cache_path = contest.cache_path
    cache = File.stat(cache_path) rescue nil

    if !cache || cache.mtime < mixtapes.map(&:updated_at).max || cache.size < 100
      File.delete(cache_path) rescue nil
      Zip::File.open(cache_path, Zip::File::CREATE) do |zip|
        mixtapes.each do |m|
          m.add_songs(zip)
        end
      end
    end

    send_file cache_path, :filename => contest.filename
  end
end
