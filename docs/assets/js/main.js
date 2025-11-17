// Scroll animation observer
const observerOptions = {
  threshold: 0.1,
  rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver(function(entries) {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('in-view');
      observer.unobserve(entry.target);
    }
  });
}, observerOptions);

// Observe all scroll-animate elements
document.querySelectorAll('.scroll-animate').forEach(el => {
  observer.observe(el);
});

// Navbar animation on scroll
let lastScrollTop = 0;
const navbar = document.querySelector('nav');

if (navbar) {
  window.addEventListener('scroll', () => {
    let scrollTop = window.pageYOffset || document.documentElement.scrollTop;

    if (scrollTop > 50) {
      navbar.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.1)';
      navbar.style.backdropFilter = 'blur(10px)';
    } else {
      navbar.style.boxShadow = 'none';
      navbar.style.backdropFilter = 'none';
    }

    lastScrollTop = scrollTop;
  });
}

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', function (e) {
    e.preventDefault();
    const target = document.querySelector(this.getAttribute('href'));
    if (target) {
      target.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      });
    }
  });
});

// Mobile menu toggle
const menuToggle = document.querySelector('.menu-toggle');
const navMenu = document.querySelector('nav ul');

if (menuToggle) {
  menuToggle.addEventListener('click', () => {
    navMenu.style.display = navMenu.style.display === 'flex' ? 'none' : 'flex';
    menuToggle.innerHTML = menuToggle.innerHTML === '☰' ? '✕' : '☰';
  });
}

// Count animation
function animateCounter(element, target, duration = 2000) {
  let current = 0;
  const increment = target / (duration / 16);

  const timer = setInterval(() => {
    current += increment;
    if (current >= target) {
      current = target;
      clearInterval(timer);
    }
    element.textContent = Math.floor(current) + '+';
  }, 16);
}

// Trigger counter animations when in view
document.querySelectorAll('[data-count]').forEach(el => {
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const target = parseInt(el.getAttribute('data-count'));
        animateCounter(el, target);
        observer.unobserve(el);
      }
    });
  }, { threshold: 0.5 });

  observer.observe(el);
});

// Parallax effect
window.addEventListener('scroll', () => {
  document.querySelectorAll('[data-parallax]').forEach(el => {
    const speed = el.getAttribute('data-parallax');
    const yPos = -(window.pageYOffset * speed);
    el.style.transform = `translateY(${yPos}px)`;
  });
});

// Add animation class on load
window.addEventListener('load', () => {
  document.querySelectorAll('[class*="animate-"]').forEach((el, index) => {
    if (!el.classList.contains('in-view')) {
      el.classList.add('in-view');
    }
  });
});

// Smooth page transitions
if (window.location.hash) {
  setTimeout(() => {
    document.querySelector(window.location.hash)?.scrollIntoView({ behavior: 'smooth' });
  }, 100);
}

// Theme toggle (optional dark mode)
const themeToggle = document.querySelector('.theme-toggle');
if (themeToggle) {
  themeToggle.addEventListener('click', () => {
    document.documentElement.style.colorScheme =
      document.documentElement.style.colorScheme === 'dark' ? 'light' : 'dark';
    localStorage.setItem('theme', document.documentElement.style.colorScheme);
  });

  // Load saved theme
  const savedTheme = localStorage.getItem('theme');
  if (savedTheme) {
    document.documentElement.style.colorScheme = savedTheme;
  }
}

// Add loading animation to images
document.querySelectorAll('img').forEach(img => {
  img.addEventListener('load', () => {
    img.style.animation = 'fadeInUp 0.6s ease-out';
  });
});

console.log('Custom Plugin Backend Tutorial - Loaded Successfully! 🚀');
