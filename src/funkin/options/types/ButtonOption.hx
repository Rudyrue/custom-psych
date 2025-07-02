package funkin.options.types;

import funkin.options.types.BaseOption;

class ButtonOption extends BaseOption<Dynamic, Dynamic> {
	/**
	 * @param name          Option Name in the options menu
	 * @param description   Descriptor for what the option does
	 * @param preference    Name of the preference it modifies (in backend.Settings)
	**/
	public function new(name:String, description:String, action:Void -> Void) {
		super(name, description);
		this.hasEnter = true;
		this.enter = action;
	}
}
