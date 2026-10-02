UNIVERSAL MASTER PROMPT
MOBILE-APP-FIRST UI/UX REDESIGN, MOTION, MICRO-INTERACTIONS, RESPONSIVE WEB, PWA & TRANSLATION
1. PRIMARY OBJECTIVE

Analyze the entire application repository and user experience, then redesign and rework its frontend so that the application feels like a modern, purposeful, professionally designed digital product rather than a generic AI-generated website.

This is a full application-wide UX/UI transformation, not simply a responsive-design task.

The objective is to create an interface that:

feels intentional;
feels product-specific;
reflects the actual business/domain context;
works exceptionally well on mobile;
intelligently expands to tablet and desktop;
uses meaningful motion and micro-interactions;
maintains a coherent design system;
provides excellent accessibility;
supports all existing business workflows;
maintains proper web navigation and SEO where applicable;
uses the application's existing localization system correctly;
eliminates generic "AI-generated" visual patterns.

The final interface must feel as if it was designed specifically for this application, its users, its industry, its geography, and its business model.

Do NOT produce a generic SaaS template.

Do NOT simply add gradients, rounded cards, shadows and animations to the existing interface.

Do NOT redesign only the homepage.

The redesign must cover the whole application.

2. UNIVERSAL DESIGN PHILOSOPHY

The primary design philosophy is:

MOBILE APPLICATION EXPERIENCE
             ↓
INTELLIGENT TABLET ADAPTATION
             ↓
EXPANDED DESKTOP APPLICATION

Do NOT use:

DESKTOP WEBSITE
       ↓
RESPONSIVE CSS
       ↓
SMALLER WEBSITE

Instead:

PRODUCT EXPERIENCE
       ↓
MOBILE-FIRST INTERACTION MODEL
       ↓
ADAPTIVE COMPONENT SYSTEM
       ↓
TABLET EXPERIENCE
       ↓
DESKTOP APPLICATION EXPERIENCE

Mobile is the primary interaction reference.

Desktop is not simply a stretched mobile layout.

Desktop should intelligently expose additional:

workspace;
information;
navigation;
contextual actions;
multi-column layouts;
data density;
productivity features.

The same product language must remain recognizable across every viewport.

3. CONTEXT-FIRST DESIGN

Before changing the visual design, understand what the application actually is.

Determine:

Application category
Target users
User roles
Primary business objectives
Core workflows
Geographic context
Cultural context where relevant
Industry conventions
User expectations
Revenue/business model
Data complexity
Frequency of use
Mobile usage patterns
Desktop usage patterns
Most important conversion/action points

Examples of application contexts include:

E-commerce
Marketplace
Service marketplace
SaaS
ERP
CRM
LMS
Education
Healthcare
Finance
Logistics
Booking
Social platform
Community platform
Government/public service
NGO/association platform
Internal enterprise application

The interface must adapt to the actual context.

Do not use the same visual solution for an ERP, marketplace, LMS and social application.

4. FULL REPOSITORY AUDIT BEFORE IMPLEMENTATION

Before modifying anything, inspect the entire repository.

Analyze:

Architecture
Framework
Frontend architecture
Backend architecture
Routing
Layout architecture
Component architecture
State management
API integration
Authentication
Authorization
Database integration
File/media management
Payment integration
Notification system
Search
Caching
PWA
SEO
Analytics
Frontend

Analyze:

Global layout
Header
Footer
Navigation
Sidebars
Bottom navigation
Mobile navigation
Components
Forms
Cards
Tables
Modals
Dialogs
Drawers
Bottom sheets
Tabs
Dropdowns
Tooltips
Toasts
Alerts
Skeletons
Loading states
Error states
Empty states
Pagination
Filters
Search
Images
Icons
Typography
Spacing
Colors
Borders
Shadows
Radius
Animations
Internationalization

Analyze:

All supported languages
Translation files
Translation keys
Missing translations
Hard-coded strings
Mixed-language interfaces
Inconsistent terminology
Pluralization
Date formatting
Number formatting
Currency formatting
RTL requirements where applicable
Responsive behavior

Analyze every major interface at:

Mobile
Large mobile
Tablet
Laptop
Desktop
Large desktop

Do not assume that responsive CSS currently works correctly.

5. CREATE A COMPLETE UI/UX AUDIT

Before implementing the redesign, create an inventory of every interface.

Classify interfaces into:

A. Global shell
Header
Footer
Main navigation
Mobile navigation
Sidebar
Global search
Notifications
User menu
Global modals
Global toasts
B. Public pages

Identify every public interface, including where applicable:

Homepage
About
Contact
FAQ
Pricing
Features
Services
Products
Marketplace
Categories
Search
Product details
Service details
Provider/seller pages
Blog
Articles
Legal pages
Privacy
Terms
Help
Landing pages
C. Authentication

Identify:

Login
Registration
OTP
Email verification
Password reset
Forgot password
New password
Social login
MFA/2FA
Account recovery
Onboarding
Welcome screens
D. User application

Identify:

User dashboard
Profile
Account
Settings
Notifications
Messages
Favorites
Wishlist
History
Orders
Bookings
Payments
Wallet
Subscriptions
E. Role-specific interfaces

Identify every role.

Examples:

Customer
Seller
Vendor
Service provider
Employee
Manager
Accountant
Teacher
Student
Moderator
Support agent
Administrator
Super Admin

Analyze every dashboard and every role-specific workflow.

F. Transactional interfaces

Where applicable:

Cart
Checkout
Payment
Booking
Confirmation
Order management
Refund
Cancellation
Delivery
Tracking
Invoices
Subscription management
G. Administration

Analyze:

Admin dashboard
User management
Role management
Content management
Product management
Service management
Order management
Payment management
Analytics
Reports
Settings
System configuration
Security
Audit logs
6. PAGE-BY-PAGE REDESIGN MATRIX

Create a complete matrix containing:

Route	Role	Current UI	Mobile	Tablet	Desktop	Problems	AI-Generic?	Priority	Redesign

For each interface identify:

What is wrong?
Why is it wrong?
What user problem does it create?
What should remain?
What should change?
What components should be reused?
What interaction should change?
What motion should be added?
What should NOT be animated?

Priorities:

P0 = Critical usability problem
P1 = Major UX/UI problem
P2 = Significant improvement
P3 = Visual polish
7. IDENTIFY "AI-GENERIC" DESIGN

Perform a specific audit for interfaces that look AI-generated, template-generated or visually generic.

Look for excessive use of:

identical rounded cards;
excessive border-radius;
random gradients;
purple/blue AI-style gradients without contextual reason;
excessive glassmorphism;
excessive shadows;
oversized headings;
generic hero sections;
generic dashboard cards;
excessive whitespace;
repetitive icon + title + description cards;
meaningless decorative blobs;
random illustrations;
unnecessary floating elements;
generic stock imagery;
excessive pills;
identical components everywhere;
arbitrary animation;
unnecessary hover effects;
inconsistent spacing;
random typography;
too many visual styles;
template-like dashboard layouts;
"AI startup" aesthetics that do not correspond to the product.

Do not remove these automatically.

First determine whether they have a legitimate design purpose.

Then replace them only when they reduce:

usability;
brand identity;
credibility;
clarity;
hierarchy;
contextual relevance.
8. DESIGN FOR THE PRODUCT, NOT FOR A TEMPLATE

Every major screen must answer:

Why does this interface look like this particular product?

The design should reflect the application's:

industry;
audience;
functionality;
brand;
business model;
geographic context;
content;
information density.

For example:

An ERP should prioritize:

productivity;
information density;
fast navigation;
tables;
filtering;
keyboard workflows;
operational clarity.

A marketplace should prioritize:

discovery;
imagery;
search;
filters;
comparison;
trust;
purchase/booking actions.

An LMS should prioritize:

learning progress;
course discovery;
lesson navigation;
completion states;
assessments;
educational hierarchy.

Do not impose the same UI pattern on every application.

9. DESIGN SYSTEM FOUNDATION

Before redesigning individual pages, establish or improve a unified design system.

Define:

Typography
Font family
Heading scale
Body scale
Caption scale
Weight hierarchy
Line heights
Letter spacing
Spacing

Create a consistent spacing scale.

Colors

Define semantic tokens:

Primary
Secondary
Accent
Background
Surface
Elevated surface
Text
Muted text
Border
Success
Warning
Error
Information

Do not select colors randomly per page.

Components

Standardize:

Buttons
Inputs
Selects
Checkboxes
Radios
Cards
Badges
Tabs
Dialogs
Drawers
Sheets
Toasts
Tables
Pagination
Navigation
Breadcrumbs
10. HEADER REDESIGN

Start the implementation with the global header.

The header must be analyzed separately for:

Public users
Authenticated users
Different roles
Mobile
Tablet
Desktop

The header must not be a generic navigation bar.

Determine the most important actions based on actual application usage.

Mobile may use:

compact header;
logo;
search;
notifications;
contextual actions;
profile;
back navigation.

Desktop may use:

expanded navigation;
search;
contextual actions;
notifications;
account controls.

Do not force every navigation item into the mobile header.

11. FOOTER REDESIGN

Redesign the global footer based on the application type.

Public websites may require:

navigation;
company information;
contact;
legal links;
social links;
language;
app/PWA links.

Authenticated application areas may require a significantly reduced footer or no conventional footer if the app-shell experience makes it unnecessary.

Do not place a traditional website footer everywhere.

12. APP SHELL

Create or improve a global application shell.

Conceptually:

<AppShell>
    <Header />
    <Navigation />
    <MainContent />
    <BottomNavigation />
    <GlobalSheets />
    <GlobalDialogs />
    <ToastLayer />
    <NotificationLayer />
</AppShell>

Adapt this to the existing framework.

The shell must support:

Mobile
compact header;
bottom navigation;
contextual actions;
sheets;
dialogs;
drawers;
touch-first controls.
Tablet
adaptive navigation;
larger content;
optional sidebar;
multi-column layouts.
Desktop
sidebar;
expanded header;
workspace;
contextual panels;
multi-column layouts;
higher information density.
13. MOBILE-FIRST APPLICATION EXPERIENCE

Every screen must first be evaluated as a mobile application interface.

Check:

touch targets;
thumb reach;
vertical hierarchy;
navigation;
content density;
scrolling;
fixed actions;
bottom navigation;
keyboard behavior;
safe areas;
mobile browser behavior.

Avoid:

tiny controls;
desktop tables;
unnecessary horizontal scrolling;
oversized desktop layouts;
hover-dependent functionality;
huge empty spaces;
excessive form complexity.
14. RESPONSIVE DESIGN

Use a single adaptive component system.

Do not create:

MobilePage
DesktopPage

unless there is a genuine architectural reason.

Prefer:

Same component
      ↓
Adaptive layout
      ↓
Adaptive interaction
      ↓
Adaptive information density

Responsive behavior should progressively adapt:

320px
360px
375px
390px
414px
430px
Tablet
1024px
1280px
1440px
1920px+

Use the existing design tokens and breakpoints whenever possible.

Avoid breakpoint proliferation.

15. DESKTOP IS AN EXPANDED APPLICATION

Desktop should not simply enlarge mobile components.

Use additional space intelligently.

For example:

Mobile:

Image
Title
Price
CTA

Desktop:

Image       Title
            Price
            Description
            Seller
            Actions

Use:

multi-column layouts;
side panels;
contextual information;
data-dense tables;
expanded navigation;
larger workspaces.

The desktop version must remain visually related to mobile.

16. NAVIGATION

Design navigation according to the actual application.

For mobile, use bottom navigation where appropriate.

For desktop, use:

sidebar;
top navigation;
contextual navigation;
tabs;
breadcrumbs;

depending on the application.

Do not blindly implement the same navigation pattern everywhere.

Navigation must support:

active state;
inactive state;
focus;
touch;
keyboard;
accessibility;
deep links;
browser history;
authentication;
role-specific access.
17. MICRO-INTERACTION SYSTEM

Introduce a coherent micro-interaction language.

Interactions should provide feedback for:

button press;
hover;
focus;
loading;
success;
error;
selection;
favorite;
toggle;
navigation;
form validation;
upload;
payment;
booking;
cart changes;
notifications.

Examples:

Idle
 ↓
Pressed
 ↓
Loading
 ↓
Success

Micro-interactions should communicate state.

They must never exist merely because animation is available.

18. MOTION / FRAMER MOTION

If the project already uses Motion/Framer Motion, integrate with it.

If not, first evaluate whether adding it is justified.

Create a centralized motion system.

Define reusable patterns:

pageEnter
pageExit
fadeIn
fadeOut
slideUp
slideDown
slideLeft
slideRight
scaleIn
scaleOut
modalEnter
modalExit
sheetEnter
sheetExit
drawerEnter
drawerExit
staggerChildren
sharedElement
press
success
error

Do not scatter arbitrary animation values throughout the application.

19. CONTEXTUAL MOTION

Motion must be adapted to the context.

Examples:

Marketplace

Product card → product details

Use continuity/shared-element-style motion where appropriate.

Booking

Step 1 → Step 2 → Confirmation

Use progression-oriented transitions.

Dashboard

Use subtle state changes and data updates.

Authentication

Use short, reassuring transitions.

Education

Use progress and completion feedback.

Finance

Use restrained motion and strong clarity.

Administration

Prioritize speed over decorative animation.

Never use the same animation strategy blindly across all modules.

20. PAGE TRANSITIONS

Implement consistent route transitions where appropriate.

Forward navigation:

Screen A
   ↓
Forward transition
   ↓
Screen B

Back navigation:

Screen B
   ↓
Reverse transition
   ↓
Screen A

Modal:

Content
   ↓
Overlay + modal/sheet

Tab:

Subtle state transition

Do not interfere with:

browser history;
deep links;
route loading;
accessibility;
performance.
21. SHARED-ELEMENT TRANSITIONS

Use shared-element-style transitions where they improve continuity.

Examples:

product → product details;
service → service details;
avatar → profile;
image thumbnail → gallery;
notification → notification detail;
listing → listing detail.

Do not force shared transitions everywhere.

22. BUTTONS

Every important button should have:

default;
hover;
pressed;
focus;
disabled;
loading;
success;
error where applicable.

Use subtle press feedback.

Avoid cartoon-like animations.

23. FORMS

Redesign forms for mobile-first usability.

Improve:

field grouping;
labels;
validation;
error messaging;
keyboard behavior;
autocomplete;
input types;
password visibility;
progress;
multi-step flows.

Do not create unnecessarily long desktop-style forms on mobile.

Where appropriate, transform complex forms into:

steps;
sheets;
sections;
progressive disclosure.
24. MODALS, DRAWERS AND BOTTOM SHEETS

Choose the correct interaction according to context.

Mobile

Prefer bottom sheets when appropriate for:

filters;
sorting;
selections;
actions;
contextual information.
Desktop

Prefer:

dialogs;
drawers;
contextual panels.

Every overlay must support:

focus management;
keyboard accessibility;
Escape;
scrolling;
safe areas;
touch;
dismissal;
accessibility.
25. LOADING STATES

Replace unnecessary generic spinners with contextual loading states.

Use:

skeletons;
progress indicators;
inline loading;
optimistic feedback where safe.

Skeletons must match the final layout to prevent layout shift.

26. EMPTY STATES

Every major module must have an intentional empty state.

Examples:

Empty cart
No orders
No bookings
No messages
No notifications
No products
No search results
No favorites

Each empty state should communicate:

What happened?
Why is it empty?
What can the user do next?

Avoid generic:

No data found.

when a more useful message is possible.

27. ERROR STATES

Create contextual recovery experiences.

Use:

inline errors;
toast errors;
retry;
recovery actions;
full-page errors only when necessary.

Do not hide real errors simply to make the interface look cleaner.

28. SKELETONS AND LAYOUT STABILITY

Every asynchronous interface should minimize:

layout shifts;
content jumps;
unexpected resizing;
flashing;
blank screens.

Reserve appropriate dimensions for:

images;
cards;
charts;
tables;
avatars.
29. DARK AND LIGHT THEMES

If the application supports dark/light themes, audit both completely.

Verify:

contrast;
surfaces;
borders;
shadows;
icons;
images;
dialogs;
sheets;
skeletons;
charts;
focus states;
motion visibility.

Never treat dark mode as simply:

background = black
text = white
30. ACCESSIBILITY

The redesign must remain accessible.

Verify:

semantic HTML;
keyboard navigation;
focus management;
focus visibility;
ARIA where appropriate;
screen-reader behavior;
color contrast;
touch targets;
form labels;
error associations.

Support:

prefers-reduced-motion

When reduced motion is enabled:

remove decorative movement;
reduce transition distances;
disable unnecessary parallax;
avoid continuous animations;
preserve state communication.
31. PERFORMANCE

Motion and visual improvements must not compromise performance.

Monitor:

LCP;
CLS;
INP;
bundle size;
hydration;
image loading;
rendering;
memory;
CPU usage;
mobile performance.

Prefer:

transform;
opacity;
compositor-friendly properties.

Avoid unnecessary:

layout animations;
heavy effects;
huge libraries;
excessive DOM complexity;
excessive re-renders.
32. IMAGES AND MEDIA

Audit all images.

Ensure:

correct aspect ratios;
optimized formats;
responsive sizes;
lazy loading where appropriate;
stable dimensions;
loading states;
error fallback;
appropriate object-fit;
accessibility alt text.

Do not use generic stock imagery when product-specific imagery is available.

33. ICONOGRAPHY

Standardize the icon system.

Do not mix:

random icon libraries;
inconsistent stroke widths;
inconsistent sizes;
inconsistent visual styles.

Icons should support the product's visual identity.

Do not replace textual meaning with icons alone where clarity would suffer.

34. DATA-DENSE INTERFACES

For ERP, admin, finance and operational interfaces, do not force everything into mobile-style cards.

Use:

responsive tables;
expandable rows;
filters;
sorting;
pagination;
drawers;
contextual panels;
bulk actions;
keyboard-friendly workflows.

On mobile, intelligently transform data rather than simply shrinking a desktop table.

35. PUBLIC PAGE REDESIGN ORDER

Redesign public interfaces systematically.

Start with:

Header
Footer
Homepage
Main landing pages
Product/service discovery
Categories
Search
Detail pages
About
Contact
FAQ
Pricing
Legal
Help/support

Every public page must share the same visual language.

36. AUTHENTICATION REDESIGN ORDER

Then redesign:

Login
Registration
Email verification
OTP
Password reset
Account recovery
Social authentication
MFA/2FA
Onboarding
Welcome experience

Authentication should feel like part of the product—not a separate generic authentication template.

37. USER EXPERIENCE REDESIGN

Redesign:

User dashboard
Profile
Settings
Notifications
Messages
Favorites
Orders
Bookings
Payments
Wallet
Subscriptions
History

Use the actual user's priorities to determine hierarchy.

38. ROLE-SPECIFIC DASHBOARDS

Identify every role and redesign its complete experience.

For every role determine:

Primary tasks
Most frequently accessed screens
Important metrics
Critical actions
Recent activity
Alerts
Navigation
Permissions
Data density

Do not give every role the same dashboard template.

A customer dashboard should not look like an admin dashboard.

A seller dashboard should not look like an employee dashboard.

39. TRANSACTIONAL FLOWS

Audit every critical business flow.

Examples:

Discovery
 ↓
Selection
 ↓
Details
 ↓
Action
 ↓
Confirmation
 ↓
Tracking
 ↓
Completion

Examples include:

purchase;
checkout;
payment;
booking;
registration;
subscription;
upload;
listing creation;
service creation;
order processing.

Every transition should clearly communicate:

current state;
next step;
success;
failure;
recovery.
40. ADMIN INTERFACE

Admin interfaces require a different design strategy.

Prioritize:

efficiency;
information density;
discoverability;
filtering;
search;
bulk operations;
auditability;
permissions;
keyboard accessibility.

Do not make admin interfaces unnecessarily decorative.

41. PWA EXPERIENCE

If the application supports PWA, audit:

manifest;
icons;
standalone mode;
splash/startup;
service worker;
caching;
installability;
offline behavior.

The PWA must feel like the actual application.

Do not claim offline functionality that is not genuinely implemented.

Never cache sensitive authenticated information insecurely.

42. SEO

For public web interfaces, preserve:

semantic HTML;
metadata;
canonical URLs;
structured data where appropriate;
crawlability;
correct heading hierarchy;
share previews;
server rendering where applicable.

The mobile-app-first experience must not become an SEO-hostile SPA.

43. PROPER WEB NAVIGATION

The application must remain a proper web application.

Users should be able to:

refresh;
bookmark;
share;
open deep links;
use browser back;
use browser forward;
open specific content directly.

Do not build a fake single-screen mobile simulation.

44. NO FAKE PHONE CONTAINER

Do NOT make desktop look like a phone mockup.

Never:

put the entire application inside a fake phone frame;
artificially restrict desktop width;
create unnecessary device borders;
waste desktop workspace.

The goal is:

Native-style interaction
+
Responsive web
+
Real URLs
+
Desktop productivity
45. INTERNATIONALIZATION / TRANSLATION AUDIT

Perform a complete translation audit after the visual audit.

Search the entire application for:

hard-coded strings;
missing translations;
untranslated buttons;
untranslated menus;
untranslated errors;
untranslated notifications;
untranslated empty states;
untranslated forms;
untranslated tooltips;
untranslated validation messages;
mixed-language screens.

Every user-facing string must use the existing i18n architecture.

Do not hard-code new text.

46. LANGUAGE CONSISTENCY

For every supported language verify:

terminology;
capitalization;
pluralization;
date;
time;
currency;
number formatting;
error messages;
navigation;
CTA wording.

Do not perform literal machine translation without considering the application's context.

Terminology must remain consistent throughout the product.

47. MOBILE TRANSLATION TESTING

Long translated text can break responsive interfaces.

Test translations on:

buttons;
tabs;
navigation;
cards;
tables;
dialogs;
bottom sheets;
forms;
notifications.

Ensure translated text does not cause:

overflow;
clipped text;
broken buttons;
unexpected wrapping;
horizontal scrolling.
48. BRAND AND VISUAL IDENTITY

The redesign must respect the application's actual brand.

Analyze:

logo;
official colors;
typography;
imagery;
tone;
brand personality.

Do not invent a new brand unless explicitly requested.

Where the existing visual identity is weak, improve its implementation without destroying recognizable brand assets.

49. COMPONENT REUSE

Create reusable components only where they genuinely improve consistency.

Potential primitives:

AppShell
AppHeader
AppFooter
AppNavigation
BottomNavigation
ResponsiveContainer
MotionPage
MotionButton
MotionCard
MotionList
MotionModal
MotionSheet
MotionDrawer
MotionDialog
MotionToast
MotionTab
MotionImage
ResponsiveTable
EmptyState
ErrorState
LoadingState

Do not create abstractions simply to increase component count.

50. CENTRALIZED MOTION TOKENS

Create a central motion configuration.

Conceptually:

motionTokens = {
    duration: {
        instant,
        fast,
        normal,
        slow
    },

    easing: {
        standard,
        enter,
        exit
    },

    spring: {
        gentle,
        responsive
    }
}

Use the actual project's architecture and technology.

Do not duplicate arbitrary animation values throughout the codebase.

51. DESIGN CONSISTENCY AUDIT

After redesigning all modules, perform a second global audit.

Check:

typography;
spacing;
buttons;
colors;
icons;
cards;
forms;
dialogs;
sheets;
navigation;
motion;
responsive behavior;
translations;
accessibility.

The application must feel like one product.

Not:

Homepage → one design
Dashboard → another design
Admin → another template
Authentication → another template
52. IMPLEMENTATION ORDER

Follow this exact implementation strategy unless the application's architecture requires a documented deviation.

PHASE 1 — DISCOVERY
Full repository analysis
Architecture analysis
Route inventory
User-role inventory
UI audit
Translation audit
Responsive audit
Accessibility audit
Performance audit
AI-generic design audit

Do not redesign yet.

PHASE 2 — DESIGN FOUNDATION

Create/improve:

Design tokens
Typography
Color system
Spacing
Radius
Shadows
Component primitives
Motion tokens
Responsive system
Theme system
PHASE 3 — GLOBAL SHELL

Redesign:

Header
Footer
Navigation
Mobile navigation
Sidebar
Global dialogs
Sheets
Toast system
Notification system

This phase establishes the application's visual language.

PHASE 4 — PUBLIC EXPERIENCE

Redesign every public interface.

Do not skip low-traffic pages.

PHASE 5 — AUTHENTICATION

Redesign the entire authentication experience.

PHASE 6 — CORE USER EXPERIENCE

Redesign:

dashboards;
profiles;
settings;
notifications;
messages;
favorites;
search;
discovery.
PHASE 7 — BUSINESS FLOWS

Redesign:

products;
services;
checkout;
payments;
bookings;
orders;
subscriptions;
uploads;
other core transactions.
PHASE 8 — ROLE-SPECIFIC APPLICATIONS

Redesign every role independently according to its actual workflow.

PHASE 9 — ADMINISTRATION

Redesign all administrative interfaces.

PHASE 10 — RESPONSIVE PASS

Test every interface across:

Mobile
Large Mobile
Tablet
Laptop
Desktop
Large Desktop
PHASE 11 — MOTION PASS

Add/refine:

page transitions;
micro-interactions;
loading transitions;
state transitions;
contextual animations;
shared-element transitions.

Do not animate everything.

PHASE 12 — TRANSLATION PASS

Verify every supported language.

PHASE 13 — ACCESSIBILITY PASS

Verify:

keyboard;
screen readers;
contrast;
focus;
reduced motion;
touch targets.
PHASE 14 — PERFORMANCE PASS

Verify:

Core Web Vitals;
bundle size;
image loading;
animation performance;
hydration;
mobile CPU/memory.
PHASE 15 — FINAL REGRESSION

Verify every existing business workflow.

Do not declare completion based solely on visual inspection.

53. RESPONSIVE TEST MATRIX

Test at minimum:

Mobile
320px
360px
375px
390px
414px
430px
Tablet

Test representative portrait and landscape widths.

Desktop
1024px
1280px
1440px
1920px

Also test:

touch;
mouse;
keyboard;
light mode;
dark mode;
reduced motion;
long translations;
slow network;
loading states;
empty states;
errors.
54. REAL USER FLOW TESTING

Test actual end-to-end workflows based on the application.

Do not invent workflows that do not exist.

For example:

User
→ Discover
→ Search
→ Select
→ View details
→ Perform action
→ Confirm
→ Complete

For transactional applications:

User
→ Product/service
→ Cart/booking
→ Checkout
→ Payment
→ Confirmation
→ Order/booking tracking

For role-based applications:

Login
→ Role dashboard
→ Core action
→ Save
→ Verify
→ Return to dashboard

Every flow must work on mobile and desktop.

55. REGRESSION REQUIREMENT

The redesign must not break:

Authentication
Authorization
Routing
API integration
Payments
Orders
Bookings
Search
Notifications
Messaging
Dashboards
Admin functionality
Translations
Themes
PWA
SEO

Do not sacrifice functionality for visual appearance.

56. DO NOT INVENT FUNCTIONALITY

The redesign must not create fake business features.

Do not add:

fake analytics;
fake statistics;
fake orders;
fake products;
fake users;
fake notifications;
fake payments;
fake integrations.

If a visual component requires data that does not exist, use the application's real data architecture or clearly identify the dependency.

Never leave mock data as a production solution.

57. DO NOT REMOVE FUNCTIONALITY

Do not remove existing features simply because:

they are difficult to redesign;
they make the interface more complex;
they require additional responsive work;
they do not fit a preferred aesthetic.

Instead redesign their presentation.

58. PERFORMANCE-AWARE MOTION

Do not add animation merely because the prompt requests Motion/Framer Motion.

For every significant animation ask:

Does this improve understanding?
Does this communicate state?
Does this improve continuity?
Does this improve feedback?
Does this improve perceived performance?

If the answer is no, do not add it.

59. ANTI-GENERIC DESIGN RULE

The final application must NOT look like it was generated from:

a generic Tailwind template;
a generic SaaS dashboard;
an AI website generator;
a random Dribbble concept;
a generic marketplace template;
a generic admin template.

Avoid visual clichés.

The objective is not:

"Make it beautiful."

The objective is:

"Make it appropriate, distinctive, usable, credible and coherent for this specific product."

60. FINAL VISUAL QUALITY STANDARD

Every redesigned interface must satisfy:

Hierarchy

The user immediately understands:

where they are;
what they can do;
what is most important;
what action comes next.
Consistency

The same interaction behaves the same way throughout the application.

Context

The interface reflects the application's actual purpose.

Responsiveness

The experience works naturally at every viewport.

Motion

Motion provides meaning rather than decoration.

Accessibility

The application remains usable without relying on motion, color or hover.

Performance

Visual polish does not compromise speed.

Localization

Every supported language remains usable and visually stable.

Product identity

The interface feels unique to the application.

61. FINAL AUDIT QUESTIONS

Before completion, answer all of the following:

Does the application feel like a real product?

Does it feel designed specifically for its target users?

Does mobile feel like a first-class experience?

Does desktop feel like an expanded application?

Does tablet behave intelligently?

Is the header appropriate to each context?

Is the footer appropriate to each context?

Is navigation intuitive?

Are dashboards role-specific?

Are public pages coherent?

Are authentication screens coherent?

Are transactional flows clear?

Are micro-interactions meaningful?

Are animations subtle and purposeful?

Does reduced-motion work?

Does dark mode work?

Does light mode work?

Are all translations complete?

Are there any hard-coded user-facing strings?

Are there any AI-generic visual patterns remaining?

Are there unnecessary gradients?

Are there unnecessary cards?

Are there unnecessary animations?

Are there inconsistent components?

Are there broken mobile layouts?

Are there horizontal overflow issues?

Are loading states polished?

Are empty states useful?

Are errors recoverable?

Is accessibility preserved?

Is performance acceptable?

Does the existing business logic still work?

If any answer is no, continue the redesign.

62. FINAL DELIVERABLE REPORT

After implementation, provide a structured report containing:

1. Application Audit

Complete repository and route analysis.

2. UX/UI Problems

List all major issues discovered.

3. AI-Generic Design Audit

List every interface that was identified as visually generic and what was changed.

4. Design System

Document:

colors;
typography;
spacing;
components;
responsive tokens.
5. App Shell

Document:

header;
footer;
navigation;
sidebar;
mobile navigation.
6. Motion System

Document all reusable motion patterns.

7. Micro-Interactions

Document implemented interaction patterns.

8. Responsive System

Document mobile/tablet/desktop behavior.

9. Public Interfaces

List redesigned public routes.

10. Authentication

List redesigned authentication interfaces.

11. User Interfaces

List redesigned user screens.

12. Role Interfaces

List every redesigned role-specific interface.

13. Admin Interfaces

List redesigned administrative interfaces.

14. Translation

Report:

supported languages;
missing translations found;
translations added;
hard-coded strings removed.
15. Accessibility

Report accessibility improvements and remaining issues.

16. Performance

Report performance findings and optimizations.

17. PWA

Report PWA improvements where applicable.

18. Testing

Report:

responsive tests;
functional tests;
E2E tests;
accessibility tests;
regression tests.
19. Remaining Issues

Explicitly list anything that remains unfinished.

Do not claim 100% completion if anything remains incomplete.

63. FINAL IMPLEMENTATION DIRECTIVE

The final product must combine:

                    PRODUCT CONTEXT
                          │
                          ▼
                 MOBILE-FIRST UX
                          │
                          ▼
                  DESIGN SYSTEM
                          │
          ┌───────────────┼────────────────┐
          ▼               ▼                ▼
       MOBILE           TABLET          DESKTOP
          │               │                │
          └───────────────┼────────────────┘
                          ▼
                   APP SHELL
                          │
                          ▼
             RESPONSIVE COMPONENTS
                          │
                          ▼
              MOTION + MICRO-INTERACTIONS
                          │
                          ▼
                ACCESSIBILITY
                          │
                          ▼
                  LOCALIZATION
                          │
                          ▼
                    PERFORMANCE
                          │
                          ▼
                  REAL BUSINESS FLOWS

The guiding principle is:

Do not make the application merely responsive. Redesign the product experience so that it behaves like a modern application on every device.

And:

Do not make it look "AI-generated beautiful." Make it look intentionally designed for the actual product.

Every design decision must have a reason.

Every animation must have a purpose.

Every component must belong to the application's design language.

Every screen must respect the user's context.

Every language must receive the same level of design quality.

Every viewport must feel intentional.

Do not stop at the homepage.

Do not stop at the public pages.

Do not stop at the dashboard.

Audit and redesign the entire application—from the global header and footer through public pages, authentication, onboarding, user interfaces, role-specific dashboards, business workflows, administration, responsive behavior, motion, accessibility and translations.