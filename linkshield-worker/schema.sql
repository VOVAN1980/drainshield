CREATE TABLE IF NOT EXISTS trusted_domains (
  domain TEXT PRIMARY KEY,
  label TEXT,
  source TEXT DEFAULT 'drainshield',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS threat_domains (
  domain TEXT PRIMARY KEY,
  verdict TEXT NOT NULL,
  risk_score INTEGER NOT NULL DEFAULT 75,
  reason TEXT,
  source TEXT DEFAULT 'drainshield',
  confidence INTEGER NOT NULL DEFAULT 50,
  report_count INTEGER NOT NULL DEFAULT 0,
  confirmed INTEGER NOT NULL DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS link_reports (
  id TEXT PRIMARY KEY,
  url_hash TEXT NOT NULL,
  domain TEXT NOT NULL,
  verdict TEXT,
  risk_score INTEGER,
  report_type TEXT NOT NULL,
  user_label TEXT,
  user_comment TEXT,
  device_hash TEXT,
  confidence_delta INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_labels (
  id TEXT PRIMARY KEY,
  domain TEXT NOT NULL,
  url_hash TEXT,
  label TEXT NOT NULL,
  comment TEXT,
  device_hash TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS source_hits (
  id TEXT PRIMARY KEY,
  domain TEXT NOT NULL,
  source TEXT NOT NULL,
  verdict TEXT NOT NULL,
  risk_score INTEGER,
  details_json TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS scan_cache (
  url_hash TEXT PRIMARY KEY,
  domain TEXT NOT NULL,
  verdict TEXT NOT NULL,
  risk_score INTEGER NOT NULL,
  reasons_json TEXT,
  checked_by TEXT DEFAULT 'DrainShield',
  expires_at TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS report_rate_limits (
  device_hash TEXT NOT NULL,
  domain TEXT NOT NULL,
  report_count INTEGER NOT NULL DEFAULT 1,
  window_start TEXT DEFAULT CURRENT_TIMESTAMP,
  last_report_at TEXT DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (device_hash, domain)
);

CREATE INDEX IF NOT EXISTS idx_link_reports_domain ON link_reports(domain);
CREATE INDEX IF NOT EXISTS idx_link_reports_device_domain ON link_reports(device_hash, domain);
CREATE INDEX IF NOT EXISTS idx_user_labels_domain ON user_labels(domain);
CREATE INDEX IF NOT EXISTS idx_source_hits_domain ON source_hits(domain);
CREATE INDEX IF NOT EXISTS idx_scan_cache_domain ON scan_cache(domain);
