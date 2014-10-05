require 'active_support'
require 'active_record'
require 'active_record_nearest_neighbor/railtie' if defined?(Rails)

class ActiveRecord::Base

  module NearestNeighbor
    extend ActiveSupport::Concern

    included do

      # ensure the lonlat attribute
      before_save :set_lonlat!

    end

    module ClassMethods
      extend ActiveSupport::Concern
      
      def bounding_box_close_to(params)
        where(%{
          ST_DWithin(
            #{self.table_name}.lonlat,
            ST_GeographyFromText('SRID=4326;POINT(%f %f)'),
              %d
          ) 
        } % [params[:longitude], params[:latitude], params[:distance]])
      end

      def k_nearest_neighbor_close_to(params)
        order(%{
          ST_GeographyFromText('SRID=4326;POINT('|| #{self.table_name}.longitude || ' ' || #{self.table_name}.latitude || ')')::geometry <-> ST_GeographyFromText('SRID=4326;POINT(%f %f)')::geometry
        } % [params[:longitude], params[:latitude]])
      end

      def close_to(longitude, latitude, options={})
        method = options[:method] || :bounding_box
        scope = "#{method}_close_to".to_sym

        options[:longitude] = longitude
        options[:latitude] = latitude

        self.send(scope,options)
      end

    end

    private

    def set_lonlat!
      self.lonlat = "POINT(#{self.longitude} #{self.latitude})"
    end
    
  end
end
