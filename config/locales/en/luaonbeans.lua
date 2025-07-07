return {
	en = {
		models = {
			errors = {
				presence = "must be present",
				numericality = {
					valid_number = "must be a valid number",
					valid_integer = "must be an integer"
				},
				length = {
					eq = "must contains %d characters",
					between = "must be a value between %d and %d characters",
					minimum = "must contains at least %d characters",
					maximum = "must contains at max %d characters"
				},
				format = "do not match the format",
				comparaison = "do not match value",
				acceptance = "you must accept",
				inclusion = "must be part of the defined list",
				exclusion = "must not be part of the defined list"
			}
		},
		demo = {
			items = {
				zero = "no items",
				one = "%d item",
				more = "%d items"
			}
		}
	}
}
