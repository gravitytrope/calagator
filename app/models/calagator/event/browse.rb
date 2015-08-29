module Calagator
  class Event < ActiveRecord::Base
    class Browse < Struct.new(:params, :start_date, :end_date)
      def events
        order.filter_by_date.filter_by_time.scope
      end

      def start_time
        parsed_start_time.strftime('%I:%M %p') if parsed_start_time
      end

      def end_time
        parsed_end_time.strftime('%I:%M %p') if parsed_end_time
      end

      protected

      def scope
        @scope ||= Event.non_duplicates.includes(:venue, :tags)
      end

      def order
        @scope = scope.ordered_by_ui_field(params[:order])
        self
      end

      def filter_by_date
        @scope = if params[:date]
          scope.within_dates(start_date, end_date)
        else
          scope.future
        end
        self
      end

      def filter_by_time
        if parsed_start_time && parsed_end_time
          @scope = within_times(scope, parsed_start_time, parsed_end_time)
        elsif parsed_start_time
          @scope = after_time(scope, parsed_start_time)
        elsif parsed_end_time
          @scope = before_time(scope, parsed_end_time)
        end
        self
      end

      private

      def parsed_start_time
        Time.zone.parse(params[:time][:start]) rescue nil
      end

      def parsed_end_time
        Time.zone.parse(params[:time][:end]) rescue nil
      end

      def within_times(scope, start_time, end_time)
        scope.order(:start_time).select do |event|
          event.start_time.hour > start_time.hour && event.end_time.hour < end_time.hour
        end
      end

      def before_time(scope, end_time)
        scope.order(:end_time).select do |event|
          event.end_time.hour < end_time.hour
        end
      end

      def after_time(scope, start_time)
        scope.order(:start_time).select do |event|
          event.start_time.hour >= start_time.hour
        end
      end
    end
  end
end
