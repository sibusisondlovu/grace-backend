-- Add unique constraint to prevent duplicate email domains
-- First, remove any existing duplicate domains (set them to NULL)
UPDATE organizations
SET domain = NULL
WHERE domain IN (
  SELECT domain
  FROM organizations
  WHERE domain IS NOT NULL
  GROUP BY domain
  HAVING COUNT(*) > 1
);

-- Add unique constraint on domain column (allowing multiple NULLs)
CREATE UNIQUE INDEX organizations_domain_unique_idx 
ON organizations (domain) 
WHERE domain IS NOT NULL;