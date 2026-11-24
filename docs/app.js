(() => {
  const I18N = {
    en: {
      "nav.preview": "Preview",
      "nav.features": "Features",
      "nav.install": "Install",
      "nav.docs": "Docs",
      "nav.download": "Download",
      "hero.eyebrow": "Native Swift · AppKit + QuartzCore · macOS 14+",
      "hero.title": "Your screenshots, <em>hung out to dry</em> on a sunlit Polaroid line.",
      "hero.subtitle": "Every time you snap a screenshot or finish a screen recording, SnapLine drops a braided clothesline across the top quarter of your Mac. Older captures gently sway left as your newest shot arcs up and clips onto the rope.",
      "hero.ctaDownload": "Download for macOS (.dmg)",
      "hero.ctaReleases": "v1.0.1 Release Notes",
      "hero.specZeroCpu": "0% Idle CPU",
      "sim.captureBtn": "Simulate New Capture",
      "sim.hint": "Drag or scroll horizontally · Hover cards · Watch the 4-stage clip animation",
      "preview.kicker": "Real Native Output",
      "preview.title": "Pure AppKit & QuartzCore. Zero Electron bloat.",
      "preview.desc": "Actual 2880×680 Retina offscreen render directly from SnapLine’s CoreGraphics procedural rope, beechwood clothespins, and GPU-accelerated layer pool.",
      "features.kicker": "Crafted for Speed & Tactility",
      "features.title": "Lightweight mechanics with unmistakable physical warmth.",
      "feat.choreoTitle": "4-Stage New Capture Physics",
      "feat.choreoDesc": "When a screenshot saves, the line lowers gently with a light breeze, older Polaroids slide left along the curve, and the new shot arcs up from the bottom-right until the wooden pin snaps shut—sending an elastic ripple down the rope.",
      "feat.perfTitle": "120fps & 0% Idle CPU",
      "feat.perfDesc": "Demand-driven CADisplayLink freezes automatically once pendulums settle. Virtualized layer pooling keeps memory tiny even with 2,000+ screenshots.",
      "feat.dragTitle": "Drag, Quick Look & Video",
      "feat.dragDesc": "Drag Polaroids straight into Slack, Figma, or Finder. Single-click for Quick Look, or hover any .mov / .mp4 screen recording for an instant inline loop.",
      "feat.scrollTitle": "1:1 Trackpad Timeline",
      "feat.scrollDesc": "Chronologically sorted oldest-left to newest-right. Native Trackpad momentum, zero implicit animation ghosting, and ahead-of-scroll thumbnail prefetching.",
      "feat.folderTitle": "Custom Location & Instant Mode",
      "feat.folderDesc": "Auto-reads your macOS screenshot folder or lets you pick any directory with optional system sync—plus a 1-click toggle to bypass macOS’s 5s thumbnail delay.",
      "feat.privacyTitle": "100% Local. Zero Telemetry. Zero Cloud.",
      "feat.privacyDesc": "Your screenshots never leave your Mac. No analytics, no accounts, no network entitlements—just an open-source Swift binary (~1.1 MB) you can inspect and build yourself.",
      "install.kicker": "Get Started in 30 Seconds",
      "install.title": "Install on macOS 14+ (Apple Silicon)",
      "install.s1Title": "Download & Drag",
      "install.s1Desc": "Grab SnapLine-1.0.1-macos-arm64.dmg from GitHub Releases and drag SnapLine.app into Applications.",
      "install.s1Btn": "Download .dmg (v1.0.1)",
      "install.s2Title": "Clear Gatekeeper (Ad-hoc Signed)",
      "install.s2Desc": "Because this open-source build is ad-hoc signed rather than Apple-notarized, run once before launching:",
      "install.s3Title": "Or Build from Source (No Xcode)",
      "install.s3Desc": "Compile and sign directly using Apple Swift Command Line Tools:",
      "common.copy": "Copy",
      "common.copied": "Copied!",
      "keys.toggle": "Toggle Clothesline",
      "keys.scroll": "Scroll History",
      "keys.ql": "Quick Look",
      "keys.drag": "Drop to Other Apps",
      "keys.dismiss": "Dismiss",
      "footer.guide": "User Guide",
      "footer.arch": "Architecture",
      "footer.troubleshoot": "Troubleshooting",
      "toast.copied": "Copied screenshot to clipboard",
      "toast.finder": "Revealed original file in Finder",
      "toast.trashed": "Unclipped & moved to Trash",
      "toast.captured": "New screenshot clipped to the line!"
    },
    vi: {
      "nav.preview": "Xem trước",
      "nav.features": "Tính năng",
      "nav.install": "Cài đặt",
      "nav.docs": "Tài liệu",
      "nav.download": "Tải về",
      "hero.eyebrow": "Swift Native · AppKit + QuartzCore · macOS 14+",
      "hero.title": "Ảnh chụp màn hình, <em>treo lên dây thừng</em> như những tấm Polaroid.",
      "hero.subtitle": "Mỗi khi bạn chụp hoặc quay màn hình xong, SnapLine hạ sợi dây thừng bện ở 1/4 trên màn hình. Ảnh cũ rung rinh trượt sang trái nhường chỗ cho ảnh mới bay lên kẹp gỗ.",
      "hero.ctaDownload": "Tải bản macOS (.dmg)",
      "hero.ctaReleases": "Ghi chú bản v1.0.1",
      "hero.specZeroCpu": "0% CPU khi nghỉ",
      "sim.captureBtn": "Chụp thử ảnh mới",
      "sim.hint": "Kéo hoặc cuộn ngang để xem ảnh cũ · Di chuột lên ảnh · Thử animation 4 pha",
      "preview.kicker": "Kết xuất Native Thực tế",
      "preview.title": "Thuần AppKit & QuartzCore. Không Electron.",
      "preview.desc": "Ảnh Retina 2880×680 xuất trực tiếp từ bộ dựng CoreGraphics của SnapLine — dây thừng bện thủ công, kẹp gỗ beechwood và layer pool mượt 120fps.",
      "features.kicker": "Thiết kế cho Độ mượt & Cảm xúc",
      "features.title": "Vật lý chân thực, siêu nhẹ và tức thì.",
      "feat.choreoTitle": "Diễn hoạt 4 pha khi chụp mới",
      "feat.choreoDesc": "Dây thừng hạ xuống kèm làn gió nhẹ làm ảnh cũ rung rinh và trượt sang trái; ảnh mới bay vút từ góc dưới phải lên và kẹp gỗ đóng chặt tạo sóng rung lan dọc sợi dây.",
      "feat.perfTitle": "Mượt 120fps & 0% CPU nghỉ",
      "feat.perfDesc": "CADisplayLink tự động tạm dừng ngay khi con lắc về cân bằng. Virtualized pool giữ RAM gọn nhẹ kể cả với hơn 2.000 ảnh chụp.",
      "feat.dragTitle": "Kéo-thả, Quick Look & Video",
      "feat.dragDesc": "Kéo thẳng Polaroid thả vào Slack, Figma, Finder. Click mở Quick Look độ nét gốc, hoặc hover lên video quay màn hình để xem trước lặp mượt.",
      "feat.scrollTitle": "Cuộn ngang 1:1 theo Trackpad",
      "feat.scrollDesc": "Sắp xếp cũ bên trái → mới nhất bên phải. Trackpad cuộn 1:1 không bóng mờ, góc nghiêng đồng nhất chống chồng lấp và tải trước thumbnail.",
      "feat.folderTitle": "Tùy chọn Thư mục & Hiện ngay",
      "feat.folderDesc": "Tự nhận thư mục screenshot của macOS, cho phép đổi thư mục kèm đồng bộ hệ thống và nút bật/tắt 1-click bỏ qua độ trễ 5s của thumbnail macOS.",
      "feat.privacyTitle": "100% Cục bộ. Không Telemetry. Mã nguồn mở.",
      "feat.privacyDesc": "Ảnh chụp hoàn toàn nằm trên máy Mac của bạn. Không tài khoản, không theo dõi, không gửi mạng — chỉ một file nhị phân Swift ~1.1 MB.",
      "install.kicker": "Sẵn sàng trong 30 giây",
      "install.title": "Cài đặt trên macOS 14+ (Apple Silicon)",
      "install.s1Title": "Tải & Kéo vào Applications",
      "install.s1Desc": "Tải file SnapLine-1.0.1-macos-arm64.dmg từ GitHub Releases và kéo SnapLine.app vào thư mục Applications.",
      "install.s1Btn": "Tải .dmg (v1.0.1)",
      "install.s2Title": "Mở khóa Gatekeeper lần đầu",
      "install.s2Desc": "Vì bản mã nguồn mở ký ad-hoc (chưa notarize Apple Developer), hãy chạy 1 dòng lệnh sau trước khi mở lần đầu:",
      "install.s3Title": "Hoặc tự Build (Không cần Xcode)",
      "install.s3Desc": "Biên dịch và đóng gói trực tiếp chỉ bằng Swift Command Line Tools:",
      "common.copy": "Chép",
      "common.copied": "Đã chép!",
      "keys.toggle": "Ẩn / Hiện dây",
      "keys.scroll": "Cuộn lịch sử",
      "keys.ql": "Quick Look",
      "keys.drag": "Kéo sang app khác",
      "keys.dismiss": "Đóng dây",
      "footer.guide": "Hướng dẫn",
      "footer.arch": "Kiến trúc",
      "footer.troubleshoot": "Sửa lỗi",
      "toast.copied": "Đã sao chép ảnh vào Clipboard",
      "toast.finder": "Đã mở tệp gốc trong Finder",
      "toast.trashed": "Đã gỡ kẹp và đưa vào Thùng rác",
      "toast.captured": "Ảnh mới đã bay lên kẹp dây!"
    }
  };

  let currentLang = localStorage.getItem("snapline_lang") || "en";

  function t(key) {
    return (I18N[currentLang] && I18N[currentLang][key]) || I18N.en[key] || key;
  }

  function applyLanguage(lang) {
    currentLang = lang;
    localStorage.setItem("snapline_lang", lang);
    document.documentElement.lang = lang;

    document.querySelectorAll(".lang-btn").forEach((btn) => {
      btn.classList.toggle("active", btn.dataset.lang === lang);
    });

    document.querySelectorAll("[data-i18n]").forEach((el) => {
      el.textContent = t(el.dataset.i18n);
    });
    document.querySelectorAll("[data-i18n-html]").forEach((el) => {
      el.innerHTML = t(el.dataset.i18nHtml);
    });
  }

  document.querySelectorAll(".lang-btn").forEach((btn) => {
    btn.addEventListener("click", () => applyLanguage(btn.dataset.lang));
  });

  // Copy command buttons
  document.querySelectorAll(".copy-code-btn").forEach((btn) => {
    btn.addEventListener("click", async () => {
      const target = document.getElementById(btn.dataset.copyTarget);
      if (!target) return;
      try {
        await navigator.clipboard.writeText(target.textContent.trim());
        btn.textContent = t("common.copied");
        setTimeout(() => {
          btn.textContent = t("common.copy");
        }, 1500);
      } catch {
        // Clipboard unavailable in insecure context
      }
    });
  });

  // ------------------------------------------------------------------
  // Interactive Physics Clothesline Playground
  // ------------------------------------------------------------------
  const stage = document.getElementById("clothesline-stage");
  const cardsLayer = document.getElementById("cards-layer");
  const ropeMain = document.getElementById("rope-path-main");
  const ropeShadow = document.getElementById("rope-path-shadow");
  const toastEl = document.getElementById("stage-toast");
  const btnCapture = document.getElementById("btn-simulate-capture");
  const btnOlder = document.getElementById("btn-scroll-older");
  const btnNewer = document.getElementById("btn-scroll-newer");

  const ARTWORKS = [
    // 0: Code Editor
    () => `<svg viewBox="0 0 160 140"><rect width="160" height="140" fill="#1C1E26"/><rect width="160" height="16" fill="#252834"/><circle cx="10" cy="8" r="2.8" fill="#FF5F56"/><circle cx="19" cy="8" r="2.8" fill="#FFBD2E"/><circle cx="28" cy="8" r="2.8" fill="#27C93F"/><rect x="14" y="28" width="54" height="5" rx="2.5" fill="#F48FB1"/><rect x="74" y="28" width="42" height="5" rx="2.5" fill="#7CCBF8"/><rect x="24" y="42" width="38" height="5" rx="2.5" fill="#A6E3A1"/><rect x="68" y="42" width="60" height="5" rx="2.5" fill="#F9E2AF"/><rect x="24" y="56" width="76" height="5" rx="2.5" fill="#89B4FA"/><rect x="34" y="70" width="46" height="5" rx="2.5" fill="#CBA6F7"/><rect x="86" y="70" width="36" height="5" rx="2.5" fill="#94E2D5"/><rect x="24" y="84" width="64" height="5" rx="2.5" fill="#FAB387"/><rect x="14" y="98" width="42" height="5" rx="2.5" fill="#CDD6F4" opacity="0.65"/><rect x="14" y="112" width="84" height="5" rx="2.5" fill="#89B4FA" opacity="0.7"/></svg>`,
    // 1: Sunset Mountains
    () => `<svg viewBox="0 0 160 140"><defs><linearGradient id="skyG" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#4A3F74"/><stop offset="55%" stop-color="#EB6B6F"/><stop offset="100%" stop-color="#F7B277"/></linearGradient></defs><rect width="160" height="140" fill="url(#skyG)"/><circle cx="96" cy="54" r="20" fill="#FFE8AD"/><path d="M0,140 L0,92 L48,68 L98,98 L160,72 L160,140 Z" fill="#3C2A4D" opacity="0.9"/><path d="M0,140 L0,108 L64,84 L126,112 L160,96 L160,140 Z" fill="#1E142C"/></svg>`,
    // 2: Analytics Chart
    () => `<svg viewBox="0 0 160 140"><rect width="160" height="140" fill="#F5F7FB"/><rect width="34" height="140" fill="#E6ECF8"/><rect x="44" y="14" width="48" height="28" rx="4" fill="#FFF"/><rect x="98" y="14" width="48" height="28" rx="4" fill="#FFF"/><rect x="48" y="86" width="12" height="38" rx="2" fill="#4681F4"/><rect x="65" y="68" width="12" height="56" rx="2" fill="#5CA8FA"/><rect x="82" y="54" width="12" height="70" rx="2" fill="#2FC69E"/><rect x="99" y="76" width="12" height="48" rx="2" fill="#F5A142"/><rect x="116" y="48" width="12" height="76" rx="2" fill="#4681F4"/><rect x="133" y="62" width="12" height="62" rx="2" fill="#2FC69E"/></svg>`,
    // 3: Palette Artboard
    () => `<svg viewBox="0 0 160 140"><rect width="160" height="140" fill="#FBF6EE"/><rect x="14" y="16" width="38" height="44" rx="5" fill="#D96B4C"/><rect x="61" y="16" width="38" height="44" rx="5" fill="#E3AA52"/><rect x="108" y="16" width="38" height="44" rx="5" fill="#428F80"/><rect x="14" y="72" width="38" height="44" rx="5" fill="#38548F"/><rect x="61" y="72" width="38" height="44" rx="5" fill="#7A5C94"/><rect x="108" y="72" width="38" height="44" rx="5" fill="#2D2926"/></svg>`,
    // 4: Terminal Pass
    () => `<svg viewBox="0 0 160 140"><rect width="160" height="140" fill="#17191C"/><circle cx="10" cy="10" r="2.6" fill="#FF5F56"/><circle cx="18" cy="10" r="2.6" fill="#FFBD2E"/><circle cx="26" cy="10" r="2.6" fill="#27C93F"/><circle cx="16" cy="34" r="4" fill="#3FD97A"/><rect x="26" y="31.5" width="84" height="5" rx="2.5" fill="#DCE3EC"/><circle cx="16" cy="52" r="4" fill="#3FD97A"/><rect x="26" y="49.5" width="102" height="5" rx="2.5" fill="#DCE3EC"/><circle cx="16" cy="70" r="4" fill="#3FD97A"/><rect x="26" y="67.5" width="72" height="5" rx="2.5" fill="#DCE3EC"/><circle cx="16" cy="88" r="4" fill="#3FD97A"/><rect x="26" y="85.5" width="96" height="5" rx="2.5" fill="#DCE3EC"/><rect x="12" y="108" width="110" height="14" rx="4" fill="#234733"/><rect x="20" y="113" width="66" height="4" rx="2" fill="#6CE892"/></svg>`,
    // 5: Studio Mockup
    () => `<svg viewBox="0 0 160 140"><defs><linearGradient id="tealG" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stop-color="#216E78"/><stop offset="100%" stop-color="#13384A"/></linearGradient></defs><rect width="160" height="140" fill="url(#tealG)"/><rect x="14" y="20" width="132" height="52" rx="6" fill="rgba(255,255,255,0.14)"/><rect x="24" y="32" width="78" height="8" rx="4" fill="#FFF" opacity="0.9"/><rect x="24" y="47" width="48" height="11" rx="5.5" fill="#F9C773"/><rect x="14" y="84" width="60" height="36" rx="5" fill="rgba(255,255,255,0.12)"/><rect x="86" y="84" width="60" height="36" rx="5" fill="rgba(255,255,255,0.12)"/></svg>`,
    // 6: Geometric Card
    () => `<svg viewBox="0 0 160 140"><rect width="160" height="140" fill="#E3CEB4"/><rect x="18" y="18" width="124" height="104" rx="6" fill="#2E241C"/><rect x="30" y="34" width="46" height="72" rx="3" fill="#FAF6EE"/><circle cx="106" cy="70" r="24" fill="#E3854F"/></svg>`
  ];

  const WOOD_PIN_SVG = `
    <svg class="wooden-pin" viewBox="0 0 28 60" aria-hidden="true">
      <defs>
        <linearGradient id="pinWood" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stop-color="#B8834B"/>
          <stop offset="35%" stop-color="#E5C090"/>
          <stop offset="70%" stop-color="#D6A972"/>
          <stop offset="100%" stop-color="#A6733D"/>
        </linearGradient>
      </defs>
      <path d="M7,54 L21,54 L21,36 Q19.5,31 21,26 L21.4,4 Q21.4,2 19.2,2 L15,2 L14.5,27 L13.5,27 L13,2 L8.8,2 Q6.6,2 6.6,4 L7,26 Q8.5,31 7,36 Z" fill="url(#pinWood)" stroke="#6E4720" stroke-width="0.9"/>
      <line x1="14" y1="33" x2="14" y2="53" stroke="#5A3918" stroke-width="0.9" opacity="0.55"/>
      <rect x="6" y="29" width="16" height="4.2" rx="1.6" fill="#B8C0CC" stroke="#58606E" stroke-width="0.7"/>
      <line x1="7" y1="30.5" x2="21" y2="30.5" stroke="#F4F7FC" stroke-width="1"/>
    </svg>
  `;

  const INITIAL_ITEMS = [
    { id: "s1", label: "18 Th11", kind: 0, tilt: -0.036, video: null },
    { id: "s2", label: "19 Th11", kind: 1, tilt: 0.031, video: null },
    { id: "s3", label: "19 Th11", kind: 2, tilt: -0.022, video: "0:14" },
    { id: "s4", label: "20 Th11", kind: 3, tilt: 0.040, video: null },
    { id: "s5", label: "20 Th11", kind: 4, tilt: -0.030, video: null },
    { id: "s6", label: "21 Th11", kind: 5, tilt: 0.024, video: null },
    { id: "s7", label: "22:15", kind: 6, tilt: -0.018, video: null }
  ];

  const SLOT_SPACING = 200;
  const ROPE_ANCHOR_Y = 44;
  const ROPE_SAG = 26;

  let cards = [];
  let scrollOffset = 0;
  let scrollTarget = null;
  let scrollSwayAngle = 0;
  let scrollSwayVel = 0;
  let lastScrollForVel = 0;
  let smoothedScrollVel = 0;
  let isPointerDragging = false;
  let dragStartX = 0;
  let dragStartScroll = 0;
  let waves = [];
  let nextSeed = 8;
  let rafId = null;
  let lastTime = 0;
  let toastTimer = null;

  function showToast(text) {
    toastEl.textContent = text;
    toastEl.classList.add("visible");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toastEl.classList.remove("visible"), 1800);
  }

  function stageWidth() {
    return stage.clientWidth || 1200;
  }

  function rightAnchorX() {
    const w = stageWidth();
    return Math.max(140, w - Math.max(48, w * 0.05) - 85);
  }

  function maxScroll() {
    const oldestX = rightAnchorX() - Math.max(0, cards.length - 1) * SLOT_SPACING;
    const leftLimit = Math.max(48, stageWidth() * 0.05) + 85;
    return Math.max(0, leftLimit - oldestX);
  }

  function ropeY(x) {
    const w = Math.max(1, stageWidth());
    const u = (2 * x / w) - 1;
    let y = ROPE_ANCHOR_Y + ROPE_SAG * Math.max(0, 1 - u * u);
    for (const wave of waves) {
      if (wave.age < 0) continue;
      const dx = x - wave.originX;
      y += wave.amp * Math.exp(-wave.damp * wave.age) * Math.sin(wave.freq * wave.age) * Math.exp(-(dx * dx) / (2 * wave.spread * wave.spread));
    }
    return y;
  }

  function buildCardElement(item) {
    const el = document.createElement("div");
    el.className = "polaroid-card";
    el.dataset.id = item.id;
    el.innerHTML = `
      ${WOOD_PIN_SVG}
      <div class="polaroid-paper">
        <div class="polaroid-well">
          ${ARTWORKS[item.kind % ARTWORKS.length]()}
          ${item.video ? `<span class="polaroid-video-badge">▶ ${item.video}</span>` : ""}
          <div class="polaroid-actions">
            <button type="button" class="card-action-btn" data-action="copy" title="Copy">
              <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
            </button>
            <button type="button" class="card-action-btn" data-action="finder" title="Finder">
              <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>
            </button>
            <button type="button" class="card-action-btn danger" data-action="trash" title="Trash">
              <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/></svg>
            </button>
          </div>
        </div>
        <div class="polaroid-chin">${item.label}</div>
      </div>
    `;

    el.addEventListener("mouseenter", () => {
      if (Math.abs(smoothedScrollVel) < 80) {
        el.classList.add("is-hovered");
        item.hovered = true;
      }
    });
    el.addEventListener("mouseleave", () => {
      el.classList.remove("is-hovered");
      item.hovered = false;
    });

    el.querySelectorAll(".card-action-btn").forEach((btn) => {
      btn.addEventListener("click", (e) => {
        e.stopPropagation();
        const act = btn.dataset.action;
        if (act === "copy") {
          btn.classList.add("success");
          showToast(t("toast.copied"));
          setTimeout(() => btn.classList.remove("success"), 1000);
        } else if (act === "finder") {
          showToast(t("toast.finder"));
        } else if (act === "trash") {
          showToast(t("toast.trashed"));
          item.removing = 0;
          item.angVel += 2.2;
          const idx = cards.indexOf(item);
          const x = rightAnchorX() - (cards.length - 1 - idx) * SLOT_SPACING + scrollOffset;
          waves.push({ originX: x, amp: -5.5, age: 0, damp: 5.0, freq: 20, spread: 140 });
          wakeLoop();
        }
      });
    });

    return el;
  }

  function addInitialCards() {
    cardsLayer.innerHTML = "";
    cards = INITIAL_ITEMS.map((spec, idx) => {
      const item = {
        ...spec,
        angle: spec.tilt,
        angVel: 0,
        shiftX: 0,
        shiftVel: 0,
        shiftDelay: 0,
        fly: null,
        pinScale: 1,
        removing: null,
        hovered: false,
        el: null
      };
      item.el = buildCardElement(item);
      item.el.style.zIndex = String(10 + idx);
      cardsLayer.appendChild(item.el);
      return item;
    });
  }

  function simulateNewCapture() {
    scrollTarget = 0;
    const kind = nextSeed % ARTWORKS.length;
    const now = new Date();
    const hh = String(now.getHours()).padStart(2, "0");
    const mm = String(now.getMinutes()).padStart(2, "0");
    const isVid = nextSeed % 3 === 0;
    nextSeed += 1;

    // Stage 1 & 2: existing cards tremble gently then glide left
    cards.forEach((c, idx) => {
      c.shiftX += SLOT_SPACING;
      c.shiftDelay = 0.16;
      const sign = idx % 2 === 0 ? 1 : -1;
      c.angVel += sign * (0.48 + (idx % 3) * 0.14);
    });

    // Stage 3: new card launches from bottom-right
    const newItem = {
      id: "sim-" + nextSeed,
      label: `${hh}:${mm}`,
      kind,
      tilt: ((nextSeed % 5) - 2) * 0.015,
      video: isVid ? "0:09" : null,
      angle: -0.22,
      angVel: 0,
      shiftX: 0,
      shiftVel: 0,
      shiftDelay: 0,
      fly: {
        elapsed: -0.22,
        duration: 0.38,
        startX: Math.min(stageWidth() - 40, rightAnchorX() + 90),
        startY: 390
      },
      pinScale: 0,
      removing: null,
      hovered: false,
      el: null
    };
    newItem.el = buildCardElement(newItem);
    newItem.el.style.opacity = "0";
    newItem.el.style.zIndex = "55";
    cardsLayer.appendChild(newItem.el);
    cards.push(newItem);

    waves.push({
      originX: stageWidth() * 0.55,
      amp: 3.5,
      age: 0,
      damp: 3.2,
      freq: 11,
      spread: Math.max(220, stageWidth() * 0.45)
    });

    showToast(t("toast.captured"));
    wakeLoop();
  }

  function stepSimulation(dt) {
    let active = false;
    const maxOff = maxScroll();

    if (scrollTarget !== null) {
      const clamped = Math.max(0, Math.min(maxOff, scrollTarget));
      const diff = clamped - scrollOffset;
      if (Math.abs(diff) > 0.4) {
        scrollOffset += diff * Math.min(1, dt * 11);
        active = true;
      } else {
        scrollOffset = clamped;
        scrollTarget = null;
      }
    } else if (!isPointerDragging) {
      if (scrollOffset < 0) {
        scrollOffset += (0 - scrollOffset) * Math.min(1, dt * 14);
        if (Math.abs(scrollOffset) < 0.3) scrollOffset = 0;
        else active = true;
      } else if (scrollOffset > maxOff) {
        scrollOffset += (maxOff - scrollOffset) * Math.min(1, dt * 14);
        if (Math.abs(scrollOffset - maxOff) < 0.3) scrollOffset = maxOff;
        else active = true;
      }
    }

    const instantVel = Math.max(-1800, Math.min(1800, (scrollOffset - lastScrollForVel) / dt));
    lastScrollForVel = scrollOffset;
    smoothedScrollVel += (instantVel - smoothedScrollVel) * Math.min(1, dt * 10);
    if (Math.abs(smoothedScrollVel) < 1 && Math.abs(instantVel) < 1) smoothedScrollVel = 0;

    const targetLean = Math.max(-0.085, Math.min(0.085, -smoothedScrollVel * 0.000075));
    const swayAlpha = -81 * (scrollSwayAngle - targetLean) - 10.4 * scrollSwayVel;
    scrollSwayVel += swayAlpha * dt;
    scrollSwayAngle += scrollSwayVel * dt;
    if (Math.abs(scrollSwayAngle - targetLean) > 0.001 || Math.abs(scrollSwayVel) > 0.003 || Math.abs(smoothedScrollVel) > 1) {
      active = true;
    } else if (targetLean === 0) {
      scrollSwayAngle = 0;
      scrollSwayVel = 0;
    }

    // Update rope waves
    waves = waves.filter((w) => {
      w.age += dt;
      const alive = w.amp * Math.exp(-w.damp * Math.max(0, w.age));
      if (Math.abs(alive) > 0.05) {
        active = true;
        return true;
      }
      return false;
    });

    // Update cards
    const toRemove = [];
    const n = cards.length;
    for (let i = 0; i < n; i++) {
      const c = cards[i];
      if (c.removing !== null) {
        c.removing = Math.min(1, c.removing + dt / 0.28);
        c.angle += c.angVel * dt;
        active = true;
        if (c.removing >= 1) toRemove.push(c);
        continue;
      }

      let shiftAccel = 0;
      if (c.shiftDelay > 0) {
        c.shiftDelay = Math.max(0, c.shiftDelay - dt);
        active = true;
      } else if (Math.abs(c.shiftX) > 0.15 || Math.abs(c.shiftVel) > 0.5) {
        const prevVel = c.shiftVel;
        const ax = -155 * c.shiftX - 18 * c.shiftVel;
        c.shiftVel += ax * dt;
        c.shiftX += c.shiftVel * dt;
        shiftAccel = ((c.shiftVel - prevVel) / dt) * 0.55;
        active = true;
      } else {
        c.shiftX = 0;
        c.shiftVel = 0;
      }

      if (c.fly) {
        c.fly.elapsed += dt;
        active = true;
        if (c.fly.elapsed >= c.fly.duration) {
          c.fly = null;
          c.pinScale = 1;
          c.angle = c.tilt + 0.09;
          c.angVel = 2.3;
          const targetX = rightAnchorX() - (n - 1 - i) * SLOT_SPACING + scrollOffset;
          waves.push({ originX: targetX, amp: 11.5, age: 0, damp: 4.4, freq: 19, spread: 190 });
          waves.push({ originX: targetX - SLOT_SPACING, amp: 3.4, age: 0, damp: 4.8, freq: 16, spread: 210 });
          if (i - 1 >= 0) cards[i - 1].angVel += 0.72;
          if (i - 2 >= 0) cards[i - 2].angVel += 0.30;
        }
      } else {
        const omega0 = 8.2;
        const zeta = c.hovered ? 0.58 : 0.24;
        const alpha = -(omega0 * omega0) * (c.angle - c.tilt) - 2 * zeta * omega0 * c.angVel + 0.00028 * shiftAccel;
        c.angVel += alpha * dt;
        c.angle = Math.max(-0.24, Math.min(0.24, c.angle + c.angVel * dt));
        if (Math.abs(c.angle - c.tilt) > 0.0015 || Math.abs(c.angVel) > 0.004) {
          active = true;
        } else {
          c.angle = c.tilt;
          c.angVel = 0;
        }
      }
    }

    if (toRemove.length > 0) {
      toRemove.forEach((c) => {
        c.el.remove();
        const idx = cards.indexOf(c);
        if (idx >= 0) cards.splice(idx, 1);
      });
    }

    renderFrame();
    return active;
  }

  function renderFrame() {
    const w = stageWidth();
    let d = "";
    for (let x = -10; x <= w + 10; x += 12) {
      const y = ropeY(x);
      d += (x === -10 ? `M${x},${y.toFixed(1)}` : ` L${x},${y.toFixed(1)}`);
    }
    ropeMain.setAttribute("d", d);
    ropeShadow.setAttribute("d", d);

    const n = cards.length;
    const rx = rightAnchorX();
    for (let i = 0; i < n; i++) {
      const c = cards[i];
      const baseX = rx - (n - 1 - i) * SLOT_SPACING + scrollOffset + c.shiftX;
      const attachY = ropeY(baseX);
      const pinEl = c.el.querySelector(".wooden-pin");

      if (c.fly) {
        if (c.fly.elapsed < 0) {
          c.el.style.opacity = "0";
          continue;
        }
        const rawT = Math.min(1, c.fly.elapsed / c.fly.duration);
        const inv = 1 - rawT;
        const tEase = 1 - inv * inv * inv;
        const cx = Math.max(c.fly.startX, baseX) + 28;
        const cy = Math.min(c.fly.startY, attachY) + 28;
        const omt = 1 - tEase;
        const px = omt * omt * c.fly.startX + 2 * omt * tEase * cx + tEase * tEase * baseX;
        const py = omt * omt * c.fly.startY + 2 * omt * tEase * cy + tEase * tEase * attachY;
        const ang = -0.22 * (1 - tEase) + 0.09 * tEase;
        const sc = 0.52 + 0.48 * tEase;
        c.el.style.opacity = String(Math.min(1, rawT / 0.25));
        c.el.style.transform = `translate3d(${px.toFixed(1)}px, ${py.toFixed(1)}px, 0) rotate(${ang.toFixed(4)}rad) scale(${sc.toFixed(3)})`;
        if (pinEl) pinEl.style.opacity = "0";
        continue;
      }

      if (c.removing !== null) {
        const t = c.removing;
        const dropY = attachY + t * t * 180;
        const sc = 1 - 0.12 * t;
        c.el.style.opacity = String(Math.max(0, 1 - t));
        c.el.style.transform = `translate3d(${baseX.toFixed(1)}px, ${dropY.toFixed(1)}px, 0) rotate(${(c.angle + t * 0.25).toFixed(4)}rad) scale(${sc.toFixed(3)})`;
        if (pinEl) pinEl.style.opacity = "0";
        continue;
      }

      const finalAngle = Math.max(-0.24, Math.min(0.24, c.angle + scrollSwayAngle));
      const sc = c.hovered ? 1.06 : 1.0;
      c.el.style.opacity = "1";
      c.el.style.transform = `translate3d(${baseX.toFixed(1)}px, ${attachY.toFixed(1)}px, 0) rotate(${finalAngle.toFixed(4)}rad) scale(${sc})`;
      if (pinEl) pinEl.style.opacity = "1";
    }
  }

  function tick(ts) {
    const dt = lastTime ? Math.min(1 / 30, Math.max(1 / 240, (ts - lastTime) / 1000)) : 1 / 60;
    lastTime = ts;
    const active = stepSimulation(dt);
    if (active || isPointerDragging) {
      rafId = requestAnimationFrame(tick);
    } else {
      rafId = null;
      lastTime = 0;
    }
  }

  function wakeLoop() {
    if (!rafId) {
      lastTime = 0;
      rafId = requestAnimationFrame(tick);
    }
  }

  // Pointer & Horizontal Trackpad Scroll (never trap vertical page scroll)
  stage.addEventListener("wheel", (e) => {
    if (Math.abs(e.deltaX) <= Math.abs(e.deltaY) || Math.abs(e.deltaX) < 0.5) return;
    e.preventDefault();
    scrollTarget = null;
    scrollOffset += -e.deltaX;
    if (scrollOffset < -40) scrollOffset = -40;
    if (scrollOffset > maxScroll() + 40) scrollOffset = maxScroll() + 40;
    wakeLoop();
  }, { passive: false });

  stage.addEventListener("pointerdown", (e) => {
    if (e.target.closest(".card-action-btn")) return;
    isPointerDragging = true;
    dragStartX = e.clientX;
    dragStartScroll = scrollOffset;
    scrollTarget = null;
    stage.setPointerCapture(e.pointerId);
    wakeLoop();
  });

  stage.addEventListener("pointermove", (e) => {
    if (!isPointerDragging) return;
    const dx = e.clientX - dragStartX;
    let next = dragStartScroll + dx;
    const maxOff = maxScroll();
    if (next < 0) next *= 0.35;
    if (next > maxOff) next = maxOff + (next - maxOff) * 0.35;
    scrollOffset = next;
  });

  stage.addEventListener("pointerup", () => {
    isPointerDragging = false;
    wakeLoop();
  });

  stage.addEventListener("pointercancel", () => {
    isPointerDragging = false;
    wakeLoop();
  });

  btnCapture.addEventListener("click", simulateNewCapture);
  btnOlder.addEventListener("click", () => {
    scrollTarget = Math.min(maxScroll(), (scrollTarget ?? scrollOffset) + SLOT_SPACING * 1.5);
    wakeLoop();
  });
  btnNewer.addEventListener("click", () => {
    scrollTarget = Math.max(0, (scrollTarget ?? scrollOffset) - SLOT_SPACING * 1.5);
    wakeLoop();
  });

  window.addEventListener("resize", () => renderFrame());

  // Initialize
  applyLanguage(currentLang);
  addInitialCards();
  renderFrame();

  // Gentle opening breeze
  setTimeout(() => {
    cards.forEach((c, idx) => {
      c.angVel += (idx % 2 === 0 ? 1 : -1) * 0.55;
    });
    wakeLoop();
  }, 350);
})();
