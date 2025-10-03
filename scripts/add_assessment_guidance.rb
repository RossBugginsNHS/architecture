#!/usr/bin/env ruby
# Adds an `assessment_guidance` block scalar to every SAF markdown file under `_safs/`
# Skips files that already contain the property. Tailors guidance by dimension.
# Idempotent: safe to re-run.

require 'pathname'

ROOT = Pathname.new(File.expand_path('..', __dir__))
SAF_DIR = ROOT.join('_safs')

DIMENSION_GUIDANCE = {
  'documentation' => {
    overview: 'Assess whether architecture documentation is current, complete enough to support decisions & delivery, and centrally discoverable.',
    verify: [
      'Single authoritative location referenced (no divergent copies)',
      'Required artefacts present OR justified as not applicable',
      'Freshness / last verified dates within agreed cadence',
      'Decisions & diagrams cross-linked (traceability chain intact)',
      'Access model enables broad read / controlled write'
    ],
    evidence: [
      'Documentation index / landing page',
      'ADR / decision log with stable IDs',
      'Freshness dashboard or metadata fields (last_verified)',
      'Capabilities / principles mapping snippet',
      'Change history (PRs / review comments)'
    ],
    gaps: [
      'Multiple stale wiki spaces / duplicate diagrams',
      'Missing decision rationale (diagram changed but no ADR)',
      'No owner / review cadence metadata',
      'Personal storage acting as de facto source'
    ],
    heuristic: 'If you cannot trace a design element to a decision & principle in < 2 clicks, documentation quality is likely insufficient.'
  },
  'decisions' => {
    overview: 'Evaluate decision hygiene: clarity, timeliness, traceability, and managed debt / exceptions.',
    verify: [
      'ADR template consistently used (context, options, consequences)',
      'Status lifecycle applied (proposed -> accepted -> superseded)',
      'Debt items tied to decisions with mitigation / target date',
      'Governance forum outcomes recorded within 24h',
      'Exceptions / deviations time-bound & reviewed'
    ],
    evidence: [
      'ADR directory with chronological IDs',
      'Decision register or index page',
      'Architecture debt register entries linking ADR IDs',
      'Governance pack / decision log extract',
      'Exception register with review dates'
    ],
    gaps: [
      'Decisions embedded only in slide decks or emails',
      'Superseded decisions deleted (lost rationale chain)',
      'Open tactical decisions with no revisit date',
      'Option analysis missing or biased'
    ],
    heuristic: 'Healthy decision flow: lead time from proposal to recorded decision < 2 governance cycles.'
  },
  'solution' => {
    overview: 'Check that the solution architecture is intentionally modelled (domains, patterns, principles) and supports evolvability & NFRs.',
    verify: [
      'Bounded contexts / domain boundaries explicit & stable',
      'Key NFR considerations embedded (resilience, security, performance)',
      'Pattern choices justified with trade-off documentation',
      'Dependencies directional / cyclic dependencies avoided or justified',
      'Threat / risk modelling performed and actions tracked'
    ],
    evidence: [
      'Context & container / component diagrams (as code preferred)',
      'Bounded context / capability map',
      'Pattern evaluation matrix or ADRs',
      'Threat model excerpt with mitigations',
      'Import / dependency graph showing absence of cycles'
    ],
    gaps: [
      'Over-fragmented microservices without domain rationale',
      'Shared database coupling between services',
      'Undocumented critical cross-cutting components',
      'Stale diagrams inconsistent with repo structure'
    ],
    heuristic: 'If a new engineer can sketch the high-level architecture accurately after 30 minutes with artefacts, the design docs are probably adequate.'
  },
  'choices' => {
    overview: 'Assess technology selection discipline: alignment to radar, NFR fitness, vendor lock awareness, managed service preference.',
    verify: [
      'Tech mapped to internal radar / catalogue with ring & status',
      'NFR benchmarks / fit analysis performed (latency, throughput, cost)',
      'Vendor lock assessment with mitigation or acceptance rationale',
      'SaaS / managed service considered before self-managed build',
      'Exit / migration triggers documented'
    ],
    evidence: [
      'Technology evaluation matrix',
      'Benchmark or load test result summary',
      'Vendor lock risk matrix / ADR',
      'Radar entry change justification',
      'Cost projection or TCO model'
    ],
    gaps: [
      'Adoption justified only by popularity / hype',
      'Absent NFR data backing selection',
      'Unplanned proprietary feature reliance',
      'No defined migration / sunset strategy'
    ],
    heuristic: 'If you cannot articulate why a simpler managed alternative was rejected in < 1 minute, re-examine the choice.'
  },
  'non functional' => {
    overview: 'Evaluate explicit definition, measurement & validation of non-functional requirements (reliability, performance, security, sustainability etc.).',
    verify: [
      'SLOs / targets documented with current measurements',
      'Load / stress / chaos test evidence exists & recent',
      'Observability pillars implemented (metrics, logs, traces)',
      'Performance & capacity model includes exceptional scenarios',
      'Security / accessibility / sustainability controls integrated early'
    ],
    evidence: [
      'SLO dashboard screenshot',
      'Load test report & trends',
      'Chaos / failure injection report',
      'Capacity forecast spreadsheet / model',
      'Security / accessibility scan summaries'
    ],
    gaps: [
      'Targets implied but not written down',
      'Single pre go-live load test only',
      'Alert noise or absence of actionable thresholds',
      'No DR / RTO-RPO articulation'
    ],
    heuristic: 'If you cannot show current error budget burn or p95 latency within a few clicks, observability maturity is low.'
  },
  'reuse' => {
    overview: 'Determine whether existing capabilities were considered, appropriately adopted, extended or consciously rejected with justification.',
    verify: [
      'Capability catalogue consulted (logged evidence)',
      'Gap / fit analysis performed for reused vs built components',
      'Extension approach non-invasive & maintainable',
      'Reuse feedback loop to platform / capability owners',
      'Future reuse potential of new capability assessed'
    ],
    evidence: [
      'Reuse decision log entries',
      'Gap analysis table',
      'Capability mapping matrix',
      'Extension request / enhancement tickets',
      'Abstraction / interface definitions'
    ],
    gaps: [
      'Parallel bespoke implementations of identical capability',
      'Forked platform code with no merge strategy',
      'Missing ROI / benefit articulation for reuse',
      'Opaque integration (no contract surfaced)'
    ],
    heuristic: 'Two teams implementing near-identical functionality is usually a missed reuse opportunity unless explicitly justified.'
  },
  'strategic' => {
    overview: 'Check explicit alignment to business capabilities, objectives, roadmap and measurable outcomes.',
    verify: [
      'Capabilities mapped (primary / supporting / consuming)',
      'Duplication analysis performed (overlap highlighted)',
      'Roadmap increments outcome-driven (not component lists)',
      'Objectives have metrics & baselines',
      'Traceability from objective -> capability -> epic -> decision'
    ],
    evidence: [
      'Capability mapping table',
      'Outcome-based roadmap slice',
      'Objective metrics dashboard',
      'Trace matrix linking objectives & ADRs',
      'Consolidation / de-duplication analysis note'
    ],
    gaps: [
      'Feature-focused roadmap lacking outcome language',
      'Capabilities implemented with no owner / metric',
      'Unexplained divergence from capability model',
      'Objectives lacking measurable target'
    ],
    heuristic: 'Every major architectural component should trace to at least one strategic objective; if not, challenge its inclusion.'
  }
}.freeze

def inject_guidance(front_matter, dimension)
  guide = DIMENSION_GUIDANCE[dimension] || DIMENSION_GUIDANCE['solution']
  lines = []
  lines << 'assessment_guidance: |\n'
  lines << '  Overview:\n'
  lines << "    #{guide[:overview]}\n"
  lines << '  What to verify:\n'
  guide[:verify].each { |v| lines << "    - #{v}\n" }
  lines << '  Evidence examples:\n'
  guide[:evidence].each { |e| lines << "    - #{e}\n" }
  lines << '  Common gaps:\n'
  guide[:gaps].each { |g| lines << "    - #{g}\n" }
  lines << '  Quick heuristic:\n'
  lines << "    #{guide[:heuristic]}\n"
  front_matter + lines.join
end

added = []
skipped = []
Dir.glob(SAF_DIR.join('**','*.md')).each do |file|
  content = File.read(file)
  next unless content.start_with?("---\n")
  parts = content.split(/^---\s*$\n/, 3)
  next unless parts.length == 3
  fm = parts[1]
  body = parts[2]
  if fm.match?(/^assessment_guidance:/)
    skipped << file
    next
  end
  # extract dimension
  dimension = fm[/^dimension:\s*([^\n]+)/,1]&.strip
  new_fm = inject_guidance(fm, dimension)
  File.write(file, ["---", new_fm, "---", body].join("\n"))
  added << file
end

puts "Added assessment_guidance to #{added.count} file(s)."
puts "Skipped (already had): #{skipped.count}" unless skipped.empty?
added.each { |f| puts " - #{Pathname.new(f).relative_path_from(ROOT)}" }