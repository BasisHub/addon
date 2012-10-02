[[ADM_USERDEFAULTS.DEFAULT_PRINTER.AVAL]]
rem --- Check alias, is it in the config file?

	port$ = callpoint!.getUserInput()

	if port$ <> "" then

		declare Config config!
		config! = cast(Config, UserObj!.get("config"))

		if !config!.isAlias(port$) then
			callpoint!.setMessage("NOT_AN_ALIAS")
			callpoint!.setStatus("ABORT")
		endif

	endif
[[ADM_USERDEFAULTS.BSHO]]
rem --- Inits

	use ::ado_config.src::Config
	use java.util.HashMap

	declare Config config!
	config! = new Config()

	declare HashMap UserObj! 
	UserObj! = new HashMap()
	UserObj!.put("config", config!)
