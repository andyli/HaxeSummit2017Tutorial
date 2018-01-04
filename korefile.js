let fs = require('fs');
let path = require('path');
let project = new Project('AgarClone', __dirname);
project.targetOptions = {"html5":{},"flash":{},"android":{},"ios":{}};
project.setDebugDir('build/linux');
Promise.all([Project.createProject('build/linux-build', __dirname), Project.createProject('/home/andy/Documents/HaxeSummit2017Tutorial/Kha', __dirname), Project.createProject('/home/andy/Documents/HaxeSummit2017Tutorial/Kha/Kore', __dirname)]).then((projects) => {
	for (let p of projects) project.addSubProject(p);
	let libs = [];
	Promise.all(libs).then((libprojects) => {
		for (let p of libprojects) project.addSubProject(p);
		resolve(project);
	});
});
