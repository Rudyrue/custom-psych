package funkin.options;

import funkin.options.BaseOption;

class ChoiceOption extends BaseOption<String, Int> {
	public var options:Array<String> = null;

	/**
	 * @param name          Option Name in the options menu
	 * @param description   Descriptor for what the option does
	 * @param preference    Name of the preference it modifies (in backend.Settings)
	 * @param options       Choice names in the options menu
	**/
	public function new(name:String, ?description:String, ?preference:String, ?options:Array<String>) {
		super(name, description, preference);
		this.options = options ?? [];
		this.hasMovement = true;
		this.change = _change;
		this.getText = _getText;
	}

    private function _getText():String {
        return value;
    }

	private function _change(next:Int) {
		if (this.options == null || this.options.length == 0)
			return;

		var next:Int = FlxMath.wrap(this.options.indexOf(this.value) + next, 0, this.options.length - 1);
		this.value = options[next];
		onChange(this.value);
	}
}
