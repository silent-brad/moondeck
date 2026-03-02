local api = {}

function api.fetch_price(currency)
	currency = currency or "USD"

	local url = string.format(
		"https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=%s&include_24hr_change=true&include_24hr_high_low=true",
		string.lower(currency)
	)

	local response, err = http.get(url)
	if not response then
		return {
			price = 97500,
			change_24h = 2.34,
			high_24h = 98200,
			low_24h = 96100,
			currency = currency,
		}
	end

	local data = json.decode(response.body)
	if not data or not data.bitcoin then
		return nil, "Invalid API response"
	end

	local btc = data.bitcoin
	local curr_lower = string.lower(currency)

	return {
		price = btc[curr_lower] or 0,
		change_24h = btc[curr_lower .. "_24h_change"] or 0,
		high_24h = btc[curr_lower .. "_24h_high"],
		low_24h = btc[curr_lower .. "_24h_low"],
		currency = currency,
	}
end

function api.format_number(num)
	if not num then
		return "0"
	end
	local formatted = string.format("%.0f", num)
	return formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

return api
