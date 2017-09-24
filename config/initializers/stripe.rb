Rails.configuration.stripe = {
  :publishable_key => ENV['P_P_KEY'],
  :secret_key => ENV['P_S_KEY']
}
Stripe.api_key = Rails.configuration.stripe[:secret_key]
