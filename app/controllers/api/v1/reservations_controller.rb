class Api::V1::ReservationsController < ApplicationController
  before_action :authenticate_with_token!
  before_action :set_reservation, only: [:approve, :decline]

  def create
    room = Room.find(params[:room_id])

    # TODO Already Booked Reservation check

    #if current_user.stripe_id.blank?
    #  render json {error: "Update your payment method", is_success: false}, status: 404
    if current_user == room.user
      render json: { error: "Your cannot book your own property", is_success: false}, status: 404
    else
      start_date = DateTime.parse(reservation_params[:start_date])
      end_date = DateTime.parse(reservation_params[:end_date])

      days = (end_date - start_date).to_i + 1
      special_days = Calendar.where(
        "room_id = ? AND status = ? AND day BETWEEN ? AND ? AND price <> ?",
        room.id, 0, start_date, end_date, room.price
      ).pluck(:price)

      # Make a reservation
      reservation = current_user.reservations.build(reservation_params)
      reservation.room = room
      reservation.price = room.price
      reservation.total = room.price * (days - special_days.count)

      special_days.each do |d|
        reservation.total += d.price
      end

      if reservation.Waiting!
        if room.Request?
          render json: { is_success: true, message: "Request sent successfully!"}, status: :ok
        else
          reservation.Approved!
          render json: { is_success: true, message: "Reservation created successfully!"}, status: :ok
        end
      else
        render json: { error: "Cannot make a reservation!", is_success: false}, status: 404
      end

    end
  end

  def reservations_by_room
    reservations = Reservation.where(room_id: params[:id])
    reservations = reservations.map { |r| ReservationSerializer.new(r, avatar_url: r.user.image) }
    render json: {reservations: reservations, is_success: true}, status: :ok
  end

  def approve
    if @reservation.room.user_id == current_user.id
      #charge(@reservation.room, @reservation)
      @reservation.Approved!
      render json: {is_success: true}, status: :ok
    else
      render json: {error: "No Permission", is_success: false}, status: 404
    end
  end

  def decline
    if @reservation.room.user_id == current_user.id
      @reservation.Declined!
      render json: {is_success: true}, status: :ok
    else
      render json: {error: "No Permission", is_success: false}, status: 404
    end
  end

  private
  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(:start_date, :end_date)
  end

  def charge
  end

end
