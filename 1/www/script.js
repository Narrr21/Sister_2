// Assembly HTTP Server Client-side JavaScript
console.log('🔧 Assembly HTTP Server - Client Side Loaded');

// Add smooth animations
document.addEventListener('DOMContentLoaded', function() {
    // Animate feature cards on load
    const cards = document.querySelectorAll('.feature-card');
    cards.forEach((card, index) => {
        card.style.animationDelay = `${index * 0.1}s`;
        card.classList.add('animate-in');
    });
    
    // Add click tracking
    const links = document.querySelectorAll('a');
    links.forEach(link => {
        link.addEventListener('click', function(e) {
            console.log('Navigating to:', this.href);
            
            // Add loading animation
            if (this.hostname === window.location.hostname) {
                document.body.style.opacity = '0.8';
                setTimeout(() => {
                    document.body.style.opacity = '1';
                }, 200);
            }
        });
    });
    
    // Server info display
    displayServerInfo();
    
    // Test connectivity
    testServerEndpoints();
});

function displayServerInfo() {
    const info = {
        'Server': 'Assembly HTTP Server',
        'Architecture': 'x86-64',
        'Protocol': 'HTTP/1.1',
        'Port': window.location.port || '8080',
        'Language': 'Assembly (AT&T Syntax)'
    };
    
    console.table(info);
}

function testServerEndpoints() {
    const endpoints = ['/', '/about', '/test'];
    
    endpoints.forEach(endpoint => {
        fetch(endpoint)
            .then(response => {
                console.log(`✅ ${endpoint}: ${response.status} ${response.statusText}`);
            })
            .catch(error => {
                console.log(`❌ ${endpoint}: Error - ${error.message}`);
            });
    });
}

// Add some interactive features
function addInteractivity() {
    // Add hover effects to feature cards
    const featureCards = document.querySelectorAll('.feature-card');
    
    featureCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-10px) scale(1.05)';
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
    });
}

// Call interactivity function
addInteractivity();