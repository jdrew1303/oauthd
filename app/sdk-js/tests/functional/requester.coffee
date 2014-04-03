exports.request = (casper, request, utils, databag) ->
	#standard endpoints
		#GET
	casper.then ->
		params = request.params
		if typeof params == "function"
			params = params databag
		request.params = params
		if (casper.cli.options.logdatabag)
			utils.dump databag
		get_defined = @evaluate( (request)->
			window.__flag = false
			window.__error = undefined
			window.request_result = undefined
			try
				window.res[request.method].apply(@, request.params)
					.done (data) ->
						window.__flag = true
						window.request_result = data
						return
					.fail (error) ->
						window.__flag = true
						window.__error = e
						return
				return true
			catch e
				window.__flag = true
				window.__error = e
				return false
			return
		, request: request)
		return

	casper.waitFor (->
		@getGlobal("__flag") is true
	), ->
		result = @evaluate(->
			window.request_result
		)
		error = @evaluate(->
			window.__error
		)
		if (error and casper.cli.options.logall)
			utils.dump error
		if (result and casper.cli.options.logall)
			utils.dump result
		@test.assert request.validate(error, result), "Request : " + request.method + " method : got expected result"
		if request.export
			request.export databag, error, result
		return

	