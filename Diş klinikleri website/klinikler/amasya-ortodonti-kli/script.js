/* ============================================================
   DİŞ KLİNİĞİ — INTERACTIONS & ANIMATIONS
   ============================================================ */

document.addEventListener('DOMContentLoaded', () => {

  // ---- Elements ----
  const header = document.getElementById('header');
  const mobileMenuBtn = document.getElementById('mobileMenuBtn');
  const mobileNav = document.getElementById('mobileNav');
  const mobileOverlay = document.getElementById('mobileOverlay');
  const appointmentForm = document.getElementById('appointmentForm');
  const formSuccess = document.getElementById('formSuccess');

  // ============================================================
  // 1. STICKY HEADER — Add shadow on scroll
  // ============================================================
  let lastScrollY = 0;

  function handleScroll() {
    const scrollY = window.scrollY;

    if (scrollY > 50) {
      header.classList.add('scrolled');
    } else {
      header.classList.remove('scrolled');
    }

    lastScrollY = scrollY;
  }

  window.addEventListener('scroll', handleScroll, { passive: true });

  // ============================================================
  // 2. MOBILE MENU — Toggle sidebar
  // ============================================================
  function openMobileMenu() {
    mobileMenuBtn.classList.add('active');
    mobileNav.classList.add('open');
    mobileOverlay.style.display = 'block';
    document.body.style.overflow = 'hidden';

    // Trigger animation
    requestAnimationFrame(() => {
      mobileOverlay.classList.add('active');
    });
  }

  function closeMobileMenu() {
    mobileMenuBtn.classList.remove('active');
    mobileNav.classList.remove('open');
    mobileOverlay.classList.remove('active');
    document.body.style.overflow = '';

    setTimeout(() => {
      mobileOverlay.style.display = 'none';
    }, 400);
  }

  mobileMenuBtn.addEventListener('click', () => {
    if (mobileNav.classList.contains('open')) {
      closeMobileMenu();
    } else {
      openMobileMenu();
    }
  });

  mobileOverlay.addEventListener('click', closeMobileMenu);

  // Close mobile menu when a link is clicked
  mobileNav.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', closeMobileMenu);
  });

  // ============================================================
  // 3. SMOOTH SCROLL — For anchor links
  // ============================================================
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      const targetId = this.getAttribute('href');
      if (targetId === '#') return;

      const target = document.querySelector(targetId);
      if (!target) return;

      e.preventDefault();

      const headerOffset = header.offsetHeight + 16;
      const elementPosition = target.getBoundingClientRect().top;
      const offsetPosition = elementPosition + window.scrollY - headerOffset;

      window.scrollTo({
        top: offsetPosition,
        behavior: 'smooth'
      });
    });
  });

  // ============================================================
  // 4. SCROLL ANIMATIONS — Intersection Observer
  // ============================================================
  const animatedElements = document.querySelectorAll('.animate-on-scroll');

  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          observer.unobserve(entry.target);
        }
      });
    }, {
      threshold: 0.1,
      rootMargin: '0px 0px -50px 0px'
    });

    animatedElements.forEach(el => observer.observe(el));
  } else {
    // Fallback: show everything immediately
    animatedElements.forEach(el => el.classList.add('visible'));
  }

  // ============================================================
  // 5. APPOINTMENT FORM — Validation & Success Message
  // ============================================================
  if (appointmentForm) {
    // Set minimum date to today
    const dateInput = document.getElementById('date');
    if (dateInput) {
      const today = new Date().toISOString().split('T')[0];
      dateInput.setAttribute('min', today);
    }

    appointmentForm.addEventListener('submit', function (e) {
      e.preventDefault();

      // Get form values
      const fullName = document.getElementById('fullName').value.trim();
      const phone = document.getElementById('phone').value.trim();
      const treatment = document.getElementById('treatment').value;
      const date = document.getElementById('date').value;

      // Basic validation
      if (!fullName || !phone || !treatment || !date) {
        return;
      }

      // Phone validation (Turkish format)
      const phoneRegex = /^(05\d{9}|5\d{9}|\+90\s?5\d{9})$/;
      const cleanPhone = phone.replace(/[\s\-\(\)]/g, '');
      if (!phoneRegex.test(cleanPhone)) {
        alert('Lütfen geçerli bir telefon numarası giriniz. (Örn: 05XX XXX XX XX)');
        return;
      }

      // Hide form, show success
      appointmentForm.style.display = 'none';
      formSuccess.classList.add('show');

      // WhatsApp message formatting
      const messageText = `Merhaba, web sitenizden randevu talebi oluşturdum:\n\n👤 *Ad Soyad:* ${fullName}\n📞 *Telefon:* ${phone}\n🦷 *İstenen Tedavi:* ${treatment}\n📅 *Tercih Edilen Tarih:* ${date}`;
      const encodedText = encodeURIComponent(messageText);

      // Get phone number from floating button
      const whatsappFloatBtn = document.querySelector('.whatsapp-float-btn');
      let targetPhone = '905330000000';
      if (whatsappFloatBtn) {
        const match = whatsappFloatBtn.href.match(/wa\.me\/(\d+)/);
        if (match) {
          targetPhone = match[1];
        }
      }

      const whatsappUrl = `https://wa.me/${targetPhone}?text=${encodedText}`;

      // Log to console
      console.log('Randevu Talebi:', {
        ad: fullName,
        telefon: phone,
        tedavi: treatment,
        tarih: date,
        whatsappUrl: whatsappUrl
      });

      // Redirect to WhatsApp after 1.5 seconds
      setTimeout(() => {
        window.open(whatsappUrl, '_blank');
      }, 1500);
    });
  }

  // ============================================================
  // 6. HERO ANIMATION — Staggered entrance
  // ============================================================
  const heroElements = document.querySelectorAll('.hero-badge, .hero h1, .hero-subtitle, .hero-buttons, .hero-highlights');

  heroElements.forEach((el, index) => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(30px)';
    el.style.transition = `all 0.7s cubic-bezier(0.25, 0.46, 0.45, 0.94) ${index * 0.15}s`;

    // Trigger animation after a short delay
    setTimeout(() => {
      el.style.opacity = '1';
      el.style.transform = 'translateY(0)';
    }, 100);
  });

  // ============================================================
  // 7. ACTIVE NAV LINK — Highlight on scroll
  // ============================================================
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-links a');

  function updateActiveNav() {
    const scrollPos = window.scrollY + header.offsetHeight + 100;

    sections.forEach(section => {
      const sectionTop = section.offsetTop;
      const sectionHeight = section.offsetHeight;
      const sectionId = section.getAttribute('id');

      if (scrollPos >= sectionTop && scrollPos < sectionTop + sectionHeight) {
        navLinks.forEach(link => {
          link.classList.remove('active');
          if (link.getAttribute('href') === `#${sectionId}`) {
            link.classList.add('active');
          }
        });
      }
    });
  }

  window.addEventListener('scroll', updateActiveNav, { passive: true });

});
