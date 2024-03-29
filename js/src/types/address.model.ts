import { poiIcons } from "@/utils/poiIcons";
import type { IPOIIcon } from "@/utils/poiIcons";

export interface IAddress {
  id?: string;
  description: string;
  street: string;
  locality: string;
  postalCode: string;
  region: string;
  country: string;
  type: string;
  geom?: string;
  url?: string;
  originId?: string;
  timezone?: string;
}

export interface IPoiInfo {
  name: string;
  alternativeName: string;
  poiIcon: IPOIIcon;
}

export class Address implements IAddress {
  country = "";

  description = "";

  locality = "";

  postalCode = "";

  region = "";

  street = "";

  type = "";

  id?: string = "";

  originId?: string = "";

  url?: string = "";

  geom?: string = "";

  timezone?: string = "";

  constructor(hash?: IAddress) {
    if (!hash) return;

    this.id = hash.id;
    this.description = hash.description?.trim();
    this.street = hash.street?.trim();
    this.locality = hash.locality?.trim();
    this.postalCode = hash.postalCode?.trim();
    this.region = hash.region?.trim();
    this.country = hash.country?.trim();
    this.type = hash.type;
    this.geom = hash.geom;
    this.url = hash.url;
    this.originId = hash.originId;
    this.timezone = hash.timezone;
  }

  get poiInfos(): IPoiInfo {
    /* generate name corresponding to poi type */
    let name = "";
    let alternativeName = "";
    let poiIcon: IPOIIcon = poiIcons.default;
    // Google Maps doesn't have a type
    if (this.type == null && this.description === this.street) {
      this.type = "house";
    }
    switch (this.type) {
      case "house":
        name = this.description;
        alternativeName = [this.postalCode, this.locality, this.country]
          .filter((zone) => zone)
          .join(", ");
        poiIcon = poiIcons.defaultAddress;
        break;
      case "street":
      case "secondary":
        name = this.description;
        alternativeName = [this.postalCode, this.locality, this.country]
          .filter((zone) => zone)
          .join(", ");
        poiIcon = poiIcons.defaultStreet;
        break;
      case "zone":
      case "city":
      case "administrative":
        name = this.postalCode
          ? `${this.description} (${this.postalCode})`
          : this.description;
        alternativeName = [this.region, this.country]
          .filter((zone) => zone)
          .join(", ");
        poiIcon = poiIcons.defaultAdministrative;
        break;
      default:
        // POI
        name = this.description;
        alternativeName = "";
        if (this.street && this.street.trim()) {
          alternativeName = `${this.street}`;
          if (this.locality) {
            alternativeName += ` (${this.locality})`;
          }
        } else if (this.locality && this.locality.trim()) {
          alternativeName = `${this.locality}, ${this.region}, ${this.country}`;
        } else if (this.region && this.region.trim()) {
          alternativeName = `${this.region}, ${this.country}`;
        } else if (this.country && this.country.trim()) {
          alternativeName = this.country;
        }
        poiIcon = this.iconForPOI;
        break;
    }
    return { name, alternativeName, poiIcon };
  }

  get fullName(): string {
    const { name, alternativeName } = this.poiInfos;
    if (name && alternativeName) {
      return `${name}, ${alternativeName}`;
    }
    if (name) {
      return name;
    }
    return "";
  }

  get iconForPOI(): IPOIIcon {
    if (this.type == null) {
      return poiIcons.default;
    }
    const type = this.type.split(":").pop() || "";
    if (poiIcons[type]) return poiIcons[type];
    return poiIcons.default;
  }
}
