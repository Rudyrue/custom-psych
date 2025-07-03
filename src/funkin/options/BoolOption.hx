package funkin.options;

import funkin.options.BaseOption;

class BoolOption extends BaseOption<Bool, Bool> {
	/**
	 * @param name          Option Name in the options menu
	 * @param description   Descriptor for what the option does
	 * @param preference    Name of the preference it modifies (in backend.Settings)
	**/
	public function new(name:String, ?description:String, ?preference:String) {
		super(name, description, preference);
		this.hasEnter = true;
		this.enter = _enter;
		this.getText = _getText;
	}

    private function _getText():String {
        return value ? "ON" : "OFF";
    }

	private function _enter():Void {
		this.value = !this.value;
		onChange(this.value);
	}
}
