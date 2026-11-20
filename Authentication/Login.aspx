
<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="Asset_Management.Authentication.Login" %>


<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>APMAS – Sign In</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />

    <link rel="stylesheet" href="../Vendor/fonts/inter/inter.css" />

 <!-- Sweet Alert -->
 <script src="../Vendor/sweetalert2/sweetalert2.all.min.js"></script>

 <!-- Font Awesome -->
 <link rel="stylesheet" href="../Vendor/fontawesome/css/all.min.css" />
    <link rel="stylesheet" href="../style/Login.css"/>
    
</head>
<body>
<form id="form1" runat="server">

<!-- Floating particle canvas -->
<canvas id="particleCanvas"></canvas>

<div class="auth-wrapper">

    <!-- ═══════════ LEFT PANEL ═══════════ -->
    <div class="auth-left" id="authLeft">

        <!-- Animated grid lines background -->
        <div class="grid-overlay"></div>

        <div class="left-brand">
            <div class="brand-icon">

            <img class="brand-icon" src="<%= ResolveUrl("~/Images/ALogoo.png") %>"/>
              <%--  <span class="brand-icon-text">AP</span>--%>
                <div class="brand-icon-ring"></div>
            </div>

            <div class="brand-info">
            <span class="brand-name">APMAS</span> 
            <div class="brand-details">
                Apparel Process Management and Administration System
            </div>
           </div>
        </div>


        <div class="left-hero" style="min-height:220px;">

            <!-- Login hero -->
            <div class="hero-panel hero-visible" id="heroLogin">
                <div class="left-eyebrow">Enterprise Management Platform</div>
               <%-- <h1 class="left-heading">One platform for<br/><span>every operation</span></h1>--%>

                <div class="logo-3d-stage" id="logoStage">
    <div class="logo-3d-entrance">
        <div class="logo-3d" id="logo3d">
            <img class="logo-3d-img" src="<%= ResolveUrl("~/Images/Logoo.png") %>"/>
        </div>
    </div>
    <div class="logo-3d-shadow"></div>
</div>

                <p class="left-sub">Manage projects, procurement, finance, and field operations from a single unified workspace.</p>
            </div>

         

        </div>

        <div class="feature-pills">
          <%--  <div class="pill" style="--pill-delay:0s"><i class="fa-solid fa-shield-halved"></i> Role-based access</div>
            <div class="pill" style="--pill-delay:0.1s"><i class="fa-solid fa-chart-line"></i> Real-time analytics</div>--%>
            <div class="pill" style="--pill-delay:0.2s"><i class="fa-solid fa-layer-group"></i> Multi-module</div>
            <div class="pill" style="--pill-delay:0.3s"><i class="fa-solid fa-lock"></i> Secure &amp; audited</div>
            <div class="pill" style="--pill-delay:0.4s"><i class="fa-solid fa-unity"></i>One Unified Platform</div>
        </div>

        <!-- 3D floating orbs -->
        <div class="orb orb-1"></div>
        <div class="orb orb-2"></div>
        <div class="orb orb-3"></div>
    </div>

    <!-- ═══════════ RIGHT PANEL ═══════════ -->
    <div class="auth-right">

        <!-- 3D card flip scene -->
        <div class="scene" id="scene">
            <div class="auth-card-wrapper" id="cardWrapper">

                <!-- ══ FRONT: LOGIN ══ -->
                <div class="auth-card" id="cardFront">

                    <!-- TAB SWITCHER -->
                  

                    <h2 class="card-title">
                        <span class="title-icon"><i class="fa-solid fa-fingerprint"></i></span>
                        Welcome Back
                    </h2>
                    <p class="card-sub">Sign in to your APMAS account</p>

                    <!-- Server error -->
                    <asp:Label ID="lblLoginError" runat="server" Visible="false" CssClass="alert-box alert-error">
                        <i class="fa-solid fa-circle-exclamation"></i>
                        <span>Invalid username or password. Please try again.</span>
                    </asp:Label>

                    <!-- Username -->
                    <div class="field-group" style="--field-delay:0.05s">
                        <label class="field-label">Username</label>
                        <div class="field-wrap" id="wrapLUser">
                            <asp:TextBox ID="txtLoginUsername" runat="server"
                                placeholder="Enter your username"
                                autocomplete="username" />
                            <i class="fa-regular fa-user field-icon"></i>
                            <div class="field-focus-bar"></div>
                        </div>
                        <div class="field-error" id="errLUser">Username is required.</div>
                    </div>

                    <!-- Password -->
                    <div class="field-group" style="--field-delay:0.1s">
                        <label class="field-label">Password</label>
                        <div class="field-wrap" id="wrapLPass">
                            <asp:TextBox ID="txtLoginPassword" runat="server"
                                TextMode="Password"
                                placeholder="Enter your password"
                                autocomplete="current-password" />
                            <i class="fa-solid fa-lock field-icon"></i>
                            <button type="button" class="toggle-pw" onclick="togglePw(this)" tabindex="-1">
                                <i class="fa-regular fa-eye"></i>
                            </button>
                            <div class="field-focus-bar"></div>
                        </div>
                        <div class="field-error" id="errLPass">Password is required.</div>
                    </div>

                    <!-- Extras -->
                    <div class="form-extras" style="--field-delay:0.15s">
                        <!----
                        <label class="remember-wrap">
                            <asp:CheckBox ID="chkRemember" runat="server" />
                            <span class="checkmark-custom"></span>
                            <span>Keep me signed in</span>
                        </label>

                            -->
                       <%-- <a href="ForgotPassword.aspx" class="forgot-link">Forgot password?</a>--%>
                    </div>
                        

                    <div class="btn-wrap" style="--field-delay:0.2s">
                        <asp:Button ID="btnLogin" runat="server"
                            CssClass="btn-submit"
                            Text="Sign In"
                            OnClick="btnLogin_Click"
                            OnClientClick="return validateLogin();" />
                        <div class="btn-glow"></div>
                    </div>

                    <p class="card-footer-note">Having trouble? Contact your system administrator.</p>
                </div>
                <!-- ══ BACK: REGISTER ══ -->
              </div>
        </div>

        <!-- Footer now flows inside auth-right, stacked below the card -->
        <div class="login-footer">
    Copyrights © <span id="copyrightYear"></span>
    <strong>Sumithra Group of Companies</strong>
    &nbsp;—&nbsp; All Rights Reserved
      <!---
    <span class="divider">|</span>
    Developed By <strong>Sumithra IT Team</strong>
          --->
</div>
    </div>

</div>


</form>

 

<script>


    (function () {
        'use strict';

        var canvas = document.getElementById('particleCanvas');
        var ctx = canvas ? canvas.getContext('2d') : null;
        var particles = [];

        function resizeCanvas() {
            if (!canvas) return;
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;
        }

        function Particle() {
            this.reset();
        }
        Particle.prototype.reset = function () {
            this.x = Math.random() * window.innerWidth;
            this.y = Math.random() * window.innerHeight;
            this.vx = (Math.random() - 0.5) * 0.4;
            this.vy = -Math.random() * 0.6 - 0.2;
            this.r = Math.random() * 1.6 + 0.4;
            this.life = Math.random();
            this.maxLife = Math.random() * 0.6 + 0.4;
            var palette = ['rgba(96,165,250,', 'rgba(167,139,250,', 'rgba(52,211,153,', 'rgba(248,113,113,'];
            this.color = palette[Math.floor(Math.random() * palette.length)];
        };
        Particle.prototype.update = function () {
            this.x += this.vx;
            this.y += this.vy;
            this.life += 0.004;
            if (this.life > this.maxLife || this.y < -10) this.reset();
        };
        Particle.prototype.draw = function () {
            var alpha = Math.sin((this.life / this.maxLife) * Math.PI) * 0.7;
            ctx.beginPath();
            ctx.arc(this.x, this.y, this.r, 0, Math.PI * 2);
            ctx.fillStyle = this.color + alpha + ')';
            ctx.fill();
        };

        function initParticles() {
            if (!ctx) return;
            resizeCanvas();
            for (var i = 0; i < 70; i++) {
                var p = new Particle();
                p.life = Math.random() * p.maxLife; // stagger start
                particles.push(p);
            }
            animateParticles();
        }

        function animateParticles() {
            if (!ctx) return;
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            particles.forEach(function (p) { p.update(); p.draw(); });
            requestAnimationFrame(animateParticles);
        }

        window.addEventListener('resize', resizeCanvas);



        var scene = document.getElementById('scene');
        var cardWrapper = document.getElementById('cardWrapper');
        var isMobile = window.matchMedia('(max-width: 768px)').matches;

        function applyTilt(e) {
            if (isMobile || !cardWrapper) return;
            var rect = scene.getBoundingClientRect();
            var cx = rect.left + rect.width / 2;
            var cy = rect.top + rect.height / 2;
            var dx = (e.clientX - cx) / (rect.width / 2);
            var dy = (e.clientY - cy) / (rect.height / 2);
            var rotX = -dy * 5;
            var rotY = dx * 5;

            if (!cardWrapper.classList.contains('flipped')) {
                cardWrapper.style.transform = 'rotateX(' + rotX + 'deg) rotateY(' + rotY + 'deg)';
            }
        }

        function resetTilt() {
            if (!cardWrapper) return;
            if (!cardWrapper.classList.contains('flipped')) {
                cardWrapper.style.transform = 'rotateX(0deg) rotateY(0deg)';
            }
        }

        if (scene) {
            scene.addEventListener('mousemove', applyTilt);
            scene.addEventListener('mouseleave', resetTilt);
        }






        window.togglePw = function (btn) {
            var input = btn.closest('.field-wrap').querySelector('input');
            var icon = btn.querySelector('i');
            if (input.type === 'password') {
                input.type = 'text';
                icon.classList.replace('fa-eye', 'fa-eye-slash');
            } else {
                input.type = 'password';
                icon.classList.replace('fa-eye-slash', 'fa-eye');
            }
            // Tiny bounce
            btn.style.transform = 'translateY(-50%) scale(1.25)';
            setTimeout(function () {
                btn.style.transform = 'translateY(-50%) scale(1)';
            }, 200);
        };



        function initRipples() {
            document.querySelectorAll('.btn-submit').forEach(function (btn) {
                btn.addEventListener('click', function (e) {
                    var rect = btn.getBoundingClientRect();
                    var ripple = document.createElement('span');
                    var size = Math.max(rect.width, rect.height) * 2;
                    ripple.className = 'ripple';
                    ripple.style.cssText = [
                        'width:' + size + 'px',
                        'height:' + size + 'px',
                        'left:' + (e.clientX - rect.left - size / 2) + 'px',
                        'top:' + (e.clientY - rect.top - size / 2) + 'px'
                    ].join(';');
                    btn.appendChild(ripple);
                    setTimeout(function () { ripple.remove(); }, 700);
                });
            });
        }


        function clearError(wrapId, errId) {
            var w = document.getElementById(wrapId);
            var e = document.getElementById(errId);
            if (w) w.classList.remove('has-error');
            if (e) e.style.display = 'none';
        }

        function showError(wrapId, errId) {
            var w = document.getElementById(wrapId);
            var e = document.getElementById(errId);
            if (w) w.classList.add('has-error');
            if (e) { e.style.display = 'block'; }
        }

        window.clearError = clearError;
        window.showError = showError;


        window.validateLogin = function () {
            var valid = true;
            var u = document.querySelector('[id$="txtLoginUsername"]');
            var p = document.querySelector('[id$="txtLoginPassword"]');

            clearError('wrapLUser', 'errLUser');
            clearError('wrapLPass', 'errLPass');

            if (!u || !u.value.trim()) { showError('wrapLUser', 'errLUser'); valid = false; }
            if (!p || !p.value.trim()) { showError('wrapLPass', 'errLPass'); valid = false; }

            if (valid) {
                var btn = document.querySelector('[id$="btnLogin"]');
                if (btn) btn.classList.add('loading');
            }
            return valid;
        };


        function initFieldAnimations() {
            document.querySelectorAll('.field-wrap input').forEach(function (input) {
                input.addEventListener('focus', function () {
                    var label = input.closest('.field-group') &&
                        input.closest('.field-group').querySelector('.field-label');
                    if (label) label.style.color = 'var(--primary)';
                });
                input.addEventListener('blur', function () {
                    var label = input.closest('.field-group') &&
                        input.closest('.field-group').querySelector('.field-label');
                    if (label) label.style.color = '';
                });
            });
        }



        function animatePills() {
            var pills = document.querySelectorAll('.pill');
            pills.forEach(function (pill, i) {
                pill.style.opacity = '0';
                setTimeout(function () {
                    pill.style.opacity = '';
                }, 300 + i * 100);
            });
        }

        function initLogo3D() {
            var stage = document.getElementById('logoStage');
            var logo = document.getElementById('logo3d');
            if (!stage || !logo) return;

            stage.addEventListener('mousemove', function (e) {
                var rect = stage.getBoundingClientRect();

                var cx = rect.left + rect.width / 2;
                var cy = rect.top + rect.height / 2;
                var dx = (e.clientX - cx) / (rect.width / 2);
                var dy = (e.clientY - cy) / (rect.height / 2);
                logo.style.transform =
                    'scale(1.18) ' +
                    'rotateX(' + (-dy * 14) + 'deg) ' +
                    'rotateY(' + (dx * 16) + 'deg) ' +
                    'translateZ(14px)';
            });

            stage.addEventListener('mouseleave', function () {
                logo.style.transform = '';
            });
        }

        document.addEventListener('DOMContentLoaded', function () {
            initParticles();
            initRipples();
            initFieldAnimations();
            animatePills();
            initLogo3D();

            var yearElement = document.getElementById('copyrightYear');

            if (yearElement) {
                yearElement.textContent = new Date().getFullYear();
            }
        });

    })();
</script>
</body>
</html>
