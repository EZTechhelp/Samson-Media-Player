function RemoveEvents() {
	console.log("Removing default event hanlders from Spotify Web")
	document.oncontextmenu = null,
	document.onmousedown = null, document.body.oncontextmenu = null, document.body.onselectstart = null,
	document.body.ondragstart = null, document.body.onmousedown = null, document.body.oncut = null,
	document.body.oncopy = null, document.body.onpaste = null, [ "copy", "cut", "paste", "select", "selectstart" ].forEach((D => {
		document.addEventListener(D, (D => {
			D.stopPropagation();
			}), true);
		})), [ "contextmenu", "copy", "cut", "paste", "mouseup", "mousedown", "keyup", "keydown", "drag", "dragstart", "select", "selectstart" ].forEach((D => {
		document.addEventListener(D, (D => {
			D.stopPropagation();
			}), true);
			}));
}
RemoveEvents();