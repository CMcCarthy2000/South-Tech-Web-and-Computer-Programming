function displayCurrentTime() {
	const now = new Date(); // Gets the current date and time
            
	const timeString = now.toLocaleTimeString(); 

	document.getElementById('time-display').textContent = timeString;
	
	}
	
displayCurrentTime();
		
setInterval(displayCurrentTime, 1000); // Refreshes the output every 1000 milliseconds