        function updateDateTime() {
            const now = new Date();
            const currentDateTime = now.toLocaleString();
            const dtBox = document.querySelector("#datetime");
            if (dtBox) dtBox.textContent = currentDateTime;
        }

        setInterval(updateDateTime, 1000);
        
        function calculateExactTimeElapsed() {
            const timeBox = document.getElementById("time-elapsed");
            if (!timeBox) return;

            const pastDate = new Date("2009-06-18T18:30:00");
            const nowDate = new Date();

            let years = nowDate.getFullYear() - pastDate.getFullYear();

            const currentAnniversary = new Date(
                nowDate.getFullYear(), 
                pastDate.getMonth(), 
                pastDate.getDate(),
                pastDate.getHours(),
                pastDate.getMinutes()
            );
            if (nowDate < currentAnniversary) {
                years--;
            }

            const lastAnniversary = new Date(
                pastDate.getFullYear() + years, 
                pastDate.getMonth(), 
                pastDate.getDate(),
                pastDate.getHours(),
                pastDate.getMinutes()
            );

            let msDifference = nowDate - lastAnniversary;

            const msPerDay = 1000 * 60 * 60 * 24;
            const msPerHour = 1000 * 60 * 60;
            const msPerMinute = 1000 * 60;

            const days = Math.floor(msDifference / msPerDay);
            msDifference %= msPerDay; 

            const hours = Math.floor(msDifference / msPerHour);
            msDifference %= msPerHour; 

            const minutes = Math.floor(msDifference / msPerMinute);

            timeBox.innerHTML = `${years} years, ${days} days, ${hours} hours, and ${minutes} minutes`;
        }

        function initAgeTracker() {
            updateDateTime();
            calculateExactTimeElapsed();
            setInterval(calculateExactTimeElapsed, 60000);
        }

        if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", initAgeTracker);
        } else {
            initAgeTracker();
        }